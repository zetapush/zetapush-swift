//
//  CometdClient.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 23/03/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift


import Foundation
import SwiftyJSON
import XCGLogger

// MARK: Subscription State
public enum CometdSubscriptionState {
    case pending(CometdSubscriptionModel)
    case subscribed(CometdSubscriptionModel)
    case queued(CometdSubscriptionModel)
    case subscribingTo(CometdSubscriptionModel)
    case unknown(CometdSubscriptionModel?)
    
    var isSubscribingTo: Bool {
        switch self {
        case .subscribingTo:
            return true
        default:
            return false
        }
    }
    
    var model: CometdSubscriptionModel? {
        switch self {
        case .pending(let model),
             .subscribed(let model),
             .queued(let model),
             .subscribingTo(let model),
             .unknown(let model?):
            return model
        default:
            return nil
        }
    }
}

// MARK: Type Aliases
public typealias ChannelSubscriptionBlock = (NSDictionary) -> Void

public struct Subscription: Equatable{
    var callback : ChannelSubscriptionBlock?
    var channel: String
    var id : Int
    
    public static func ==(lhs: Subscription, rhs: Subscription) -> Bool {
        return lhs.id == rhs.id && lhs.channel == rhs.channel
    }
}

// MARK: CometdClient
open class CometdClient : TransportDelegate {
    open var cometdURLString:String?
    open var handshakeFields:[String:AnyObject]?
    open var cometdClientId:String?
    
    open weak var delegate:CometdClientDelegate?
    
    var transport:WebsocketTransport?
    
    open var cometdConnected:Bool?
    
    let log = XCGLogger(identifier: "cometdLogger", includeDefaultDestinations: true)
    
    var connectionInitiated:Bool?
    var messageNumber:UInt32 = 0
    
    var forceSecure:Bool = false
    
    var logLevel: XCGLogger.Level = .severe
    
    var queuedSubscriptions = Array<CometdSubscriptionModel>()
    var pendingSubscriptions = Array<CometdSubscriptionModel>()
    var openSubscriptions = Array<CometdSubscriptionModel>()
    
    var channelSubscriptionBlocks = Dictionary<String, Array<Subscription>>()
    
    lazy var pendingSubscriptionSchedule: Timer = {
        return Timer.scheduledTimer(
            timeInterval: 45,
            target: self,
            selector: #selector(pendingSubscriptionsAction(_:)),
            userInfo: nil,
            repeats: true
        )
    }()
    
    /// Default in 10 seconds
    let timeOut: Int
    
    let readOperationQueue = DispatchQueue(label: "com.zetapush.cometdclient.read", attributes: [])
    let writeOperationQueue = DispatchQueue(label: "com.zetapush.cometdclient.write", attributes: DispatchQueue.Attributes.concurrent)
    
    // MARK: Init
    public init(timeoutAdvice:Int=10000) {
        self.cometdConnected = false;
        self.connectionInitiated = false;
        self.timeOut = timeoutAdvice
    }
    
    deinit {
        pendingSubscriptionSchedule.invalidate()
    }
    
    open func setLogLevel(logLevel: XCGLogger.Level){
        self.log.setup(level: logLevel)
        self.logLevel = logLevel
    }
    
    open func configure(url: String, backoffIncrement: Int=1000, maxBackoff: Int=60000, appendMessageTypeToURL: Bool = false){
        
        // Check protocol (only websocket for now)
        let rawUrl = URL(string: url)
        let port = rawUrl?.port
        let path = rawUrl?.path
        let host = rawUrl?.host
        var scheme: String = "ws://"
        if forceSecure {
            scheme = "wss://"
        }
        
        if rawUrl?.port != nil {
            self.cometdURLString = scheme + host! + ":" + String(port!) + path!
            
        } else {
            self.cometdURLString = scheme + host! + path!
        }
        
        self.cometdConnected = false;
        
        self.transport = WebsocketTransport(url: self.cometdURLString!, logLevel: self.logLevel)
        self.transport!.delegate = self;
    }
    
    open func connectHandshake(_ handshakeFields:[String:AnyObject]) {
        self.handshakeFields = handshakeFields
        log.debug("CometdClient handshake")
        
        if self.connectionInitiated != true {
            self.transport?.openConnection()
            self.connectionInitiated = true;
        } else {
            log.debug("Cometd: Connection established")
        }
    }
    
    open func getCometdClientId() -> String {
        return self.cometdClientId ?? ""
    }
    
    open func isConnected() -> Bool {
        return self.cometdConnected ?? false
    }
    
    open func setForceSecure(_ isSecure: Bool){
        self.forceSecure = isSecure
    }
    
    open func disconnectFromServer() {
        unsubscribeAllSubscriptions()
        
        self.disconnect()
    }
    
    open func sendMessage(_ messageDict: NSDictionary, channel:String) {
        self.publish(messageDict as! Dictionary, channel: channel)
    }
    
    open func sendMessage(_ messageDict:[String:AnyObject], channel:String) {
        self.publish(messageDict, channel: channel)
    }
    
    open func modelToSubscription(tuple: ModelBlockTuple) -> (state: CometdSubscriptionState, subscription: Subscription?) {
        let model = tuple.model
        var sub = Subscription(callback:nil, channel: model.subscriptionUrl, id: 0)
        if let block = tuple.block {
            
            if self.channelSubscriptionBlocks[model.subscriptionUrl] == nil {
                self.channelSubscriptionBlocks[model.subscriptionUrl] = []
            }
            sub.callback = block
            sub.id = self.channelSubscriptionBlocks[model.subscriptionUrl]!.count
            
            self.channelSubscriptionBlocks[model.subscriptionUrl]!.append(sub)
        }
        
        if self.isSubscribedToChannel(model.subscriptionUrl) {
            // If channel is already subscribed
            log.info("CometdClient subscribeToChannel intial subscription")
            return (.subscribed(model), sub)
        } else if self.pendingSubscriptions.contains(where: { $0 == model }) {
            // If channel is already in pending status
            log.info("CometdClient subscribeToChannel pending subscription")
            return (.pending(model), sub)
        } else if self.cometdConnected == false {
            // If connection is not yet established
            self.queuedSubscriptions.append(model)
            return (.queued(model), sub)
        } else {
            return (.subscribingTo(model), sub)
        }
    }
    
    open func subscribeToChannel(_ channel: String, block: ChannelSubscriptionBlock? = nil) -> (state: CometdSubscriptionState, subscription: Subscription?) {
        let model = CometdSubscriptionModel(subscriptionUrl: channel, clientId: cometdClientId)
        let tuple = ModelBlockTuple(model: model, block: block)
        return modelToSubscription(tuple: tuple)
    }
    
    open func subscribeToChannel(_ model: CometdSubscriptionModel, block: ChannelSubscriptionBlock? = nil) -> (state: CometdSubscriptionState, subscription: Subscription?) {
        let tuple = ModelBlockTuple(model: model, block: block)
        return modelToSubscription(tuple: tuple)
    }
    
    open func unsubscribeFromChannel(_ subscription:Subscription) {
        _ = removeChannelFromQueuedSubscriptions(subscription.channel)
        
        var subscriptionArray = self.channelSubscriptionBlocks[subscription.channel]
        if let index = subscriptionArray?.index(of: subscription){
            subscriptionArray?.remove(at: index)
        }
        if subscriptionArray?.count == 0 {
            self.unsubscribe(subscription.channel)
            
            self.channelSubscriptionBlocks[subscription.channel] = nil;
            _ = removeChannelFromOpenSubscriptions(subscription.channel)
            _ = removeChannelFromPendingSubscriptions(subscription.channel)
        }
        
    }
    
    open func clearSubscriptionFromChannel(_ subscription: Subscription) {
        _ = removeChannelFromQueuedSubscriptions(subscription.channel)
        // Empty the multi-callback storage array
        self.channelSubscriptionBlocks[subscription.channel]?.removeAll()
        // Unsubscribe from the server
        self.unsubscribe(subscription.channel)
        
        self.channelSubscriptionBlocks[subscription.channel] = nil;
        _ = removeChannelFromOpenSubscriptions(subscription.channel)
        _ = removeChannelFromPendingSubscriptions(subscription.channel)
        
    }
}
