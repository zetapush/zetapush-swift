//
//  CometdClient+Bayeux.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 23/03/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift


import Foundation
import SwiftyJSON
import XCGLogger

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


// MARK: Bayuex Connection Type
public enum BayeuxConnection: String {
    case LongPolling = "long-polling"
    case Callback = "callback-polling"
    case iFrame = "iframe"
    case WebSocket = "websocket"
}

// MARK: BayeuxChannel Messages
public enum BayeuxChannel: String {
    case Handshake = "/meta/handshake"
    case Connect = "/meta/connect"
    case Disconnect = "/meta/disconnect"
    case Subscribe = "/meta/subscribe"
    case Unsubscibe = "/meta/unsubscribe"
}

// MARK: Bayeux Parameters
public enum Bayeux: String {
    case Channel = "channel"
    case Version = "version"
    case ClientId = "clientId"
    case ConnectionType = "connectionType"
    case Data = "data"
    case Subscription = "subscription"
    case Id = "id"
    case MinimumVersion = "minimumVersion"
    case SupportedConnectionTypes = "supportedConnectionTypes"
    case Successful = "successful"
    case Error = "error"
    case Advice = "advice"
    case Ext = "ext"
}

public enum BayeuxAdvice: String {
    case Interval = "interval"
    case Reconnect = "reconnect"
    case Timeout = "timeout"
}

public enum BayeuxAdviceReconnect: String {
    case None = "none"
    case Retry = "retry"
    case Handshake = "handshake"
}

// MARK: Private Bayuex Methods
extension CometdClient {
    
    /**
     Bayeux messages
     */
    
    // Bayeux Handshake
    // "channel": "/meta/handshake",
    // "version": "1.0",
    // "minimumVersion": "1.0beta",
    // "supportedConnectionTypes": ["long-polling", "callback-polling", "iframe", "websocket]
    func handshake(_ data:[String:AnyObject]) {
        writeOperationQueue.sync { [unowned self] in
            let connTypes:NSArray = [BayeuxConnection.LongPolling.rawValue, BayeuxConnection.Callback.rawValue, BayeuxConnection.iFrame.rawValue, BayeuxConnection.WebSocket.rawValue]
            
            var dict = [String: AnyObject]()
            dict[Bayeux.Channel.rawValue] = BayeuxChannel.Handshake.rawValue as AnyObject?
            dict[Bayeux.Version.rawValue] = "1.0" as AnyObject?
            dict[Bayeux.MinimumVersion.rawValue] = "1.0" as AnyObject?
            dict[Bayeux.SupportedConnectionTypes.rawValue] = connTypes
            
            var ext = [String: AnyObject]()
            ext["authentication"] = data as AnyObject?
            
            var advice = [String: AnyObject]()
            advice["interval"] = 0 as AnyObject?
            advice["timeout"] = 6000 as AnyObject?
            
            dict["ext"] = ext as AnyObject?
            dict["advice"] = advice as AnyObject?
            
            if let string = JSON(dict).rawString(String.Encoding.utf8, options: []) {
                self.log.verbose("CometdClient handshake \(string)")
                self.transport?.writeString("["+string+"]")
            }
        }
    }
    
    // Bayeux Connect
    // "channel": "/meta/connect",
    // "clientId": "Un1q31d3nt1f13r",
    // "connectionType": "long-polling"
    func connect() {
        writeOperationQueue.sync { [unowned self] in
            let dict:[String:AnyObject] = [
                Bayeux.Channel.rawValue: BayeuxChannel.Connect.rawValue as AnyObject,
                Bayeux.ClientId.rawValue: self.cometdClientId! as AnyObject,
                Bayeux.ConnectionType.rawValue: BayeuxConnection.WebSocket.rawValue as AnyObject,
                Bayeux.Advice.rawValue: ["timeout": self.timeOut] as AnyObject
            ]
            
            if let string = JSON(dict).rawString(String.Encoding.utf8, options: []) {
                self.log.verbose("CometdClient connect \(string)")
                self.transport?.writeString("["+string+"]")
            }
        }
    }
    
    // Bayeux Disconnect
    // "channel": "/meta/disconnect",
    // "clientId": "Un1q31d3nt1f13r"
    func disconnect() {
        guard let cometdClientId = self.cometdClientId else { return }
        writeOperationQueue.sync { [unowned self] in
            let dict:[String:AnyObject] = [Bayeux.Channel.rawValue: BayeuxChannel.Disconnect.rawValue as AnyObject, Bayeux.ClientId.rawValue: cometdClientId as AnyObject, Bayeux.ConnectionType.rawValue: BayeuxConnection.WebSocket.rawValue as AnyObject]
            if let string = JSON(dict).rawString(String.Encoding.utf8, options: []) {
                self.log.verbose("CometdClient disconnect \(string)")
                self.transport?.writeString("["+string+"]")
            }
        }
    }
    
    // Bayeux Subscribe
    // "channel": "/meta/subscribe",
    // "clientId": "Un1q31d3nt1f13r",
    // "subscription": "/foo/**"
    func subscribe(_ model:CometdSubscriptionModel) {
        writeOperationQueue.sync { [unowned self] in
            do {
                let json = try model.jsonString()
                self.log.verbose("CometdClient subscribe \(json)")
                
                self.transport?.writeString("["+json+"]")
                self.pendingSubscriptions.append(model)
            } catch CometdSubscriptionModelError.conversationError {
                
            } catch CometdSubscriptionModelError.clientIdNotValid
                where self.cometdClientId?.characters.count > 0 {
                    let model = model
                    model.clientId = self.cometdClientId
                    self.subscribe(model)
            } catch {
                
            }
        }
    }
    
    // Bayeux Unsubscribe
    // {
    // "channel": "/meta/unsubscribe",
    // "clientId": "Un1q31d3nt1f13r",
    // "subscription": "/foo/**"
    // }
    func unsubscribe(_ channel:String) {
        writeOperationQueue.sync { [unowned self] in
            if let clientId = self.cometdClientId {
                let dict:[String:AnyObject] = [Bayeux.Channel.rawValue: BayeuxChannel.Unsubscibe.rawValue as AnyObject, Bayeux.ClientId.rawValue: clientId as AnyObject, Bayeux.Subscription.rawValue: channel as AnyObject]
                
                if let string = JSON(dict).rawString(String.Encoding.utf8, options: []) {
                    self.log.verbose("CometdClient unsubscribe \(string)")
                    self.transport?.writeString("["+string+"]")
                }
            }
        }
    }
    
    // Bayeux Publish
    // {
    // "channel": "/some/channel",
    // "clientId": "Un1q31d3nt1f13r",
    // "data": "some application string or JSON encoded object",
    // "id": "some unique message id"
    // }
    func publish(_ data:[String:AnyObject], channel:String) {
        writeOperationQueue.sync { [weak self] in
            if let clientId = self?.cometdClientId, let messageId = self?.nextMessageId(), self?.cometdConnected == true {
                let dict:[String:AnyObject] = [
                    Bayeux.Channel.rawValue: channel as AnyObject,
                    Bayeux.ClientId.rawValue: clientId as AnyObject,
                    Bayeux.Id.rawValue: messageId as AnyObject,
                    Bayeux.Data.rawValue: data as AnyObject
                ]
                
                if let string = JSON(dict).rawString(String.Encoding.utf8, options: []) {
                    self?.log.verbose("CometdClient Publish \(string)")
                    self?.transport?.writeString("["+string+"]")
                }
            }
        }
    }
}
