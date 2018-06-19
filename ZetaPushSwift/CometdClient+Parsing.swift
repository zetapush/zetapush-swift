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
    
    func parseCometdMessage(_ messages:JSON) {
        let message = messages[0]
        if let channel = message[Bayeux.Channel.rawValue].string {
            log.verbose("parseCometdMessage \(channel)")
            log.verbose(message)
            
            // Handle Meta Channels
            if let metaChannel = BayeuxChannel(rawValue: channel) {
                switch(metaChannel) {
                case .Handshake:
                    self.cometdClientId = message[Bayeux.ClientId.rawValue].stringValue
                    if message[Bayeux.Successful.rawValue].int == 1 {
                        if message[Bayeux.Ext.rawValue] != JSON.null {
                            let ext : AnyObject = message[Bayeux.Ext.rawValue].object as AnyObject
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
                    let advice = message[Bayeux.Advice.rawValue];
                    let successful = message[Bayeux.Successful.rawValue];
                    let reconnect = advice[BayeuxAdvice.Reconnect.rawValue].stringValue
                    if successful.boolValue {
                        if (reconnect == BayeuxAdviceReconnect.Retry.rawValue) {
                            self.cometdConnected = true;
                            self.delegate?.connectedToServer(self)
                            self.connect()
                        } else {
                            self.cometdConnected = false;
                        }
                    } else {
                        
                        self.cometdConnected = false;
                        self.transport?.closeConnection()
                        self.delegate?.disconnectedFromServer(self)
                        if (reconnect == BayeuxAdviceReconnect.Handshake.rawValue) {
                            self.delegate?.disconnectedAdviceReconnect(self)
                        }
                    }
                case .Disconnect:
                    if message[Bayeux.Successful.rawValue].boolValue {
                        self.cometdConnected = false;
                        self.transport?.closeConnection()
                        self.delegate?.disconnectedFromServer(self)
                    } else {
                        self.cometdConnected = false;
                        self.transport?.closeConnection()
                        self.delegate?.disconnectedFromServer(self)
                    }
                case .Subscribe:
                    if let success = message[Bayeux.Successful.rawValue].int, success == 1 {
                        if let subscription = message[Bayeux.Subscription.rawValue].string {
                            _ = removeChannelFromPendingSubscriptions(subscription)
                            
                            self.openSubscriptions.append(CometdSubscriptionModel(subscriptionUrl: subscription, clientId: cometdClientId))
                            self.delegate?.didSubscribeToChannel(self, channel: subscription)
                        } else {
                            log.warning("Cometd: Missing subscription for Subscribe")
                        }
                    } else {
                        // Subscribe Failed
                        if let error = message[Bayeux.Error.rawValue].string,
                            let subscription = message[Bayeux.Subscription.rawValue].string {
                            _ = removeChannelFromPendingSubscriptions(subscription)
                            
                            self.delegate?.subscriptionFailedWithError(
                                self,
                                error: subscriptionError.error(subscription: subscription, error: error)
                            )
                        }
                    }
                case .Unsubscibe:
                    if let subscription = message[Bayeux.Subscription.rawValue].string {
                        _ = removeChannelFromOpenSubscriptions(subscription)
                        self.delegate?.didUnsubscribeFromChannel(self, channel: subscription)
                    } else {
                        log.warning("Cometd: Missing subscription for Unsubscribe")
                    }
                }
            } else {
                // Handle Client Channel
                if self.isSubscribedToChannel(channel) {
                    if message[Bayeux.Data.rawValue] != JSON.null {
                        let data: AnyObject = message[Bayeux.Data.rawValue].object as AnyObject
                        
                        if let channelBlock = self.channelSubscriptionBlocks[channel] {
                            for channel in channelBlock {
                                channel.callback!(data as! NSDictionary)
                            }
                        } else {
                            log.warning("Cometd: Failed to get channel block for : \(channel)")
                        }
                        
                        self.delegate?.messageReceived(
                            self,
                            messageDict: data as! NSDictionary,
                            channel: channel
                        )
                    } else {
                        log.warning("Cometd: For some reason data is nil for channel: \(channel)")
                    }
                } else {
                    log.warning("Cometd: Weird channel that not been set to subscribed: \(channel)")
                }
            }
        } else {
            log.warning("Cometd: Missing channel for \(message)")
        }
    }
}

