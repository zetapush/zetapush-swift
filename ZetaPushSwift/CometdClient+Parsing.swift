//
//  CometdClient+Parsing.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 23/03/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

import Foundation
import SwiftyJSON

extension CometdClient {
    
    // MARK:
    // MARK: Parsing
    
    func parseCometdMessage(_ messageJSON:JSON) {
        let messageDict = messageJSON[0]
        if let channel = messageDict[Bayeux.Channel.rawValue].string {
            print("parseCometdMessage", channel, messageDict)
            // Handle Meta Channels
            if let metaChannel = BayeuxChannel(rawValue: channel) {
                switch(metaChannel) {
                case .Handshake:
                    self.cometdClientId = messageDict[Bayeux.ClientId.rawValue].stringValue
                    if messageDict[Bayeux.Successful.rawValue].int == 1 {
                        self.delegate?.connectedToServer(self)
                        if messageJSON[0][Bayeux.Ext.rawValue] != JSON.null {
                            let ext : AnyObject = messageDict[Bayeux.Ext.rawValue].object as AnyObject
                            self.delegate?.handshakeSucceeded(self, handshakeDict: ext as! NSDictionary)
                        }
                        self.cometdConnected = true;
                        self.connect()
                        self.subscribeQueuedSubscriptions()
                        _ = pendingSubscriptionSchedule.isValid
                    } else {
                        self.delegate?.handshakeFailed(self)
                        self.cometdConnected = false;
                        self.transport?.closeConnection()
                        self.delegate?.disconnectedFromServer(self)
                    }
                case .Connect:
                    if messageDict[Bayeux.Successful.rawValue].int == 1 {
                        self.cometdConnected = true;
                        self.connect()
                    } else {
                        self.cometdConnected = false;
                        self.transport?.closeConnection()
                        self.delegate?.disconnectedFromServer(self)
                    }
                case .Disconnect:
                    if messageDict[Bayeux.Successful.rawValue].int == 1 {
                        self.cometdConnected = false;
                        self.transport?.closeConnection()
                        self.delegate?.disconnectedFromServer(self)
                    } else {
                        self.cometdConnected = false;
                        self.transport?.closeConnection()
                        self.delegate?.disconnectedFromServer(self)
                    }
                case .Subscribe:
                    if let success = messageJSON[0][Bayeux.Successful.rawValue].int, success == 1 {
                        if let subscription = messageJSON[0][Bayeux.Subscription.rawValue].string {
                            _ = removeChannelFromPendingSubscriptions(subscription)
                            
                            self.openSubscriptions.append(CometdSubscriptionModel(subscriptionUrl: subscription, clientId: cometdClientId))
                            self.delegate?.didSubscribeToChannel(self, channel: subscription)
                        } else {
                            print("Cometd: Missing subscription for Subscribe")
                        }
                    } else {
                        // Subscribe Failed
                        if let error = messageJSON[0][Bayeux.Error.rawValue].string,
                            let subscription = messageJSON[0][Bayeux.Subscription.rawValue].string {
                            _ = removeChannelFromPendingSubscriptions(subscription)
                            
                            self.delegate?.subscriptionFailedWithError(
                                self,
                                error: subscriptionError.error(subscription: subscription, error: error)
                            )
                        }
                    }
                case .Unsubscibe:
                    if let subscription = messageJSON[0][Bayeux.Subscription.rawValue].string {
                        _ = removeChannelFromOpenSubscriptions(subscription)
                        self.delegate?.didUnsubscribeFromChannel(self, channel: subscription)
                    } else {
                        print("Cometd: Missing subscription for Unsubscribe")
                    }
                }
            } else {
                // Handle Client Channel
                if self.isSubscribedToChannel(channel) {
                    if messageJSON[0][Bayeux.Data.rawValue] != JSON.null {
                        let data: AnyObject = messageJSON[0][Bayeux.Data.rawValue].object as AnyObject
                        
                        if let channelBlock = self.channelSubscriptionBlocks[channel] {
                            for channel in channelBlock {
                                channel.callback!(data as! NSDictionary)
                            }
                        } else {
                            print("Cometd: Failed to get channel block for : \(channel)")
                        }
                        
                        self.delegate?.messageReceived(
                            self,
                            messageDict: data as! NSDictionary,
                            channel: channel
                        )
                    } else {
                        print("Cometd: For some reason data is nil for channel: \(channel)")
                    }
                } else {
                    print("Cometd: Weird channel that not been set to subscribed: \(channel)")
                }
            }
        } else {
            print("Cometd: Missing channel for \(messageDict)")
        }
    }
}

