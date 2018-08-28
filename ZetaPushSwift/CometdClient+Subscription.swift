//
//  CometdClient+Subscription.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 23/03/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

import Foundation
import SwiftyJSON


// MARK: Private Internal methods
extension CometdClient {
    
    func subscribeQueuedSubscriptions() {
        // if there are any outstanding open subscriptions resubscribe
        for channel in self.queuedSubscriptions {
            _ = removeChannelFromQueuedSubscriptions(channel.subscriptionUrl)
            _ = subscribeToChannel(channel)
        }
    }
    
    func resubscribeToPendingSubscriptions() {
        if !pendingSubscriptions.isEmpty {
            log.debug("Cometd: Resubscribing to \(pendingSubscriptions.count) pending subscriptions")
            
            for channel in pendingSubscriptions {
                _ = removeChannelFromPendingSubscriptions(channel.subscriptionUrl)
                _ = subscribeToChannel(channel)
            }
        }
    }
    
    func unsubscribeAllSubscriptions() {
        let all = queuedSubscriptions + openSubscriptions + pendingSubscriptions
        
        all.forEach({ clearSubscriptionFromChannel(Subscription(callback: nil, channel:$0.subscriptionUrl, id:$0.id!)) })
    }
    
    // MARK:
    // MARK: Send/Receive
    
    func send(_ message: NSDictionary) {
        writeOperationQueue.async { [unowned self] in
            if let string = JSON(message).rawString() {
                self.transport?.writeString(string)
            }
        }
    }
    
    func receive(_ message: String) {
        readOperationQueue.sync { [unowned self] in
            if let jsonData = message.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                if let json = try? JSON(data: jsonData) {
                    self.parseCometdMessage(json)
                }
            }
        }
    }
    
    func nextMessageId() -> String {
        self.messageNumber += 1
        
        if self.messageNumber >= UINT32_MAX {
            messageNumber = 0
        }
        
        return "\(self.messageNumber)".encodedString()
    }
    
    // MARK:
    // MARK: Subscriptions
    
    func removeChannelFromQueuedSubscriptions(_ channel: String) -> Bool {
        objc_sync_enter(self.queuedSubscriptions)
        defer { objc_sync_exit(self.queuedSubscriptions) }
        
        let index = self.queuedSubscriptions.index { $0.subscriptionUrl == channel }
        
        if let index = index {
            self.queuedSubscriptions.remove(at: index)
            
            return true
        }
        
        return false
    }
    
    func removeChannelFromPendingSubscriptions(_ channel: String) -> Bool {
        objc_sync_enter(self.pendingSubscriptions)
        defer { objc_sync_exit(self.pendingSubscriptions) }
        
        let index = self.pendingSubscriptions.index { $0.subscriptionUrl == channel }
        
        if let index = index {
            self.pendingSubscriptions.remove(at: index)
            
            return true
        }
        
        return false
    }
    
    func removeChannelFromOpenSubscriptions(_ channel: String) -> Bool {
        objc_sync_enter(self.pendingSubscriptions)
        defer { objc_sync_exit(self.pendingSubscriptions) }
        
        let index = self.openSubscriptions.index { $0.subscriptionUrl == channel }
        
        if let index = index {
            self.openSubscriptions.remove(at: index)
            
            return true
        }
        
        return false
    }
}

