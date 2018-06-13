//
//  CometdClientDelegate.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 23/03/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

import Foundation

public enum subscriptionError: Error {
    case error(subscription: String, error: String)
}

// MARK: CometdClientDelegate Protocol
public protocol CometdClientDelegate: NSObjectProtocol {
    func messageReceived(_ client:CometdClient, messageDict: NSDictionary, channel: String)
    func pongReceived(_ client:CometdClient)
    func connectedToServer(_ client:CometdClient)
    func handshakeSucceeded(_ client:CometdClient, handshakeDict: NSDictionary)
    func handshakeFailed(_ client:CometdClient)
    func disconnectedFromServer(_ client:CometdClient)
    func connectionFailed(_ client:CometdClient)
    func didSubscribeToChannel(_ client:CometdClient, channel:String)
    func didUnsubscribeFromChannel(_ client:CometdClient, channel:String)
    func subscriptionFailedWithError(_ client:CometdClient, error:subscriptionError)
    func cometdClientError(_ client:CometdClient, error:NSError)
    func reconnect(_ client:CometdClient)
}

public extension CometdClientDelegate {
    func messageReceived(_ client:CometdClient, messageDict: NSDictionary, channel: String){}
    func pongReceived(_ client:CometdClient){}
    func connectedToServer(_ client:CometdClient){}
    func handshakeSucceeded(_ client:CometdClient, handshakeDict: NSDictionary){}
    func handshakeFailed(_ client:CometdClient){}
    func disconnectedFromServer(_ client:CometdClient){}
    func connectionFailed(_ client:CometdClient){}
    func didSubscribeToChannel(_ client:CometdClient, channel:String){}
    func didUnsubscribeFromChannel(_ client:CometdClient, channel:String){}
    func subscriptionFailedWithError(_ client:CometdClient, error:subscriptionError){}
    func cometdClientError(_ client:CometdClient, error:NSError){}
    func reconnect(_ client:CometdClient){}
}

