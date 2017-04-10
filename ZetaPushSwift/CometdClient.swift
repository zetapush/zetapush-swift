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

// MARK: Subscription State
public enum CometdSubscriptionState {
    case pending(CometdSubscriptionModel)
    case subscribed(CometdSubscriptionModel)
    case queued(CometdSubscriptionModel)
    case subscribingTo(CometdSubscriptionModel)
    case unknown(CometdSubscriptionModel?)
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
    
    open internal(set) var cometdConnected:Bool? {
        didSet {
            if cometdConnected == false {
                unsubscribeAllSubscriptions()
            }
        }
    }
    
    var connectionInitiated:Bool?
    var messageNumber:UInt32 = 0
    
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
    
    open func configure(url: String, backoffIncrement: Int=1000, maxBackoff: Int=60000, appendMessageTypeToURL: Bool = false){
        self.cometdURLString = url
        self.cometdConnected = false;
        
        self.transport = WebsocketTransport(url: url)
        self.transport!.delegate = self;
    }
    
    open func connectHandshake(_ handshakeFields:[String:AnyObject]) {
        self.handshakeFields = handshakeFields
        print("CometdClient handshake")
        
        if self.connectionInitiated != true {
            self.transport?.openConnection()
            self.connectionInitiated = true;
        } else {
            print("Cometd: Connection established")
        }
    }
    
    open func getCometdClientId() -> String {
        return self.cometdClientId ?? ""
    }
    
    open func isConnected() -> Bool {
        return self.cometdConnected ?? false
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
    
    open func sendPing(_ data: Data, completion: (() -> ())?) {
        writeOperationQueue.async { [unowned self] in
            self.transport?.sendPing(data, completion: completion)
        }
    }
    
    open func subscribeToChannel(_ model:CometdSubscriptionModel, block:ChannelSubscriptionBlock?=nil) -> (CometdSubscriptionState, Subscription?) {
        guard !self.isSubscribedToChannel(model.subscriptionUrl) else {
            return (.subscribed(model), nil)
        }
        
        guard !self.pendingSubscriptions.contains(where: { $0 == model }) else {
            return (.pending(model), nil)
        }
        
        var sub = Subscription(callback:nil, channel: model.subscriptionUrl, id: 0)
        if let block = block {
        
            if self.channelSubscriptionBlocks[model.subscriptionUrl] == nil
            {
                self.channelSubscriptionBlocks[model.subscriptionUrl] = []
            }
        
            sub.callback = block
            sub.id = self.channelSubscriptionBlocks[model.subscriptionUrl]!.count
        
            self.channelSubscriptionBlocks[model.subscriptionUrl]!.append(sub)
        }
        
        if self.cometdConnected == false {
            self.queuedSubscriptions.append(model)
            
            return (.queued(model), sub)
        }
        
        self.subscribe(model)
        
        return (.subscribingTo(model), sub)
    }
    
    open func subscribeToChannel(_ channel:String, block:ChannelSubscriptionBlock?=nil) -> (CometdSubscriptionState, Subscription?) {
        return subscribeToChannel(
            CometdSubscriptionModel(subscriptionUrl: channel, clientId: cometdClientId),
            block: block
        )
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
