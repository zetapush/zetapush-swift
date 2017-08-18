//
//  ClientHelperDelegate.swift
//  Pods
//
//  Created by Mikael Morvan on 09/08/2017.
//
//

import Foundation

// MARK: CometdClientDelegate Protocol
public protocol ClientHelperDelegate: NSObjectProtocol {
    func onConnectionEstablished(_ client:ClientHelper)
    func onConnectionBroken(_ client:ClientHelper)
    func onConnectionClosed(_ client:ClientHelper)
    func onSuccessfulHandshake(_ client:ClientHelper)
    func onFailedHandshake(_ client:ClientHelper)
    func onDidSubscribeToChannel(_ client:ClientHelper, channel:String)
    func onDidUnsubscribeFromChannel(_ client:ClientHelper, channel:String)
    func onSubscriptionFailedWithError(_ client:ClientHelper, error:subscriptionError)
}


public extension ClientHelperDelegate {
    func onConnectionEstablished(_ client:ClientHelper){}
    func onConnectionBroken(_ client:ClientHelper){}
    func onConnectionClosed(_ client:ClientHelper){}
    func onSuccessfulHandshake(_ client:ClientHelper){}
    func onFailedHandshake(_ client:ClientHelper){}
    func onDidSubscribeToChannel(_ client:ClientHelper, channel:String){}
    func onDidUnsubscribeFromChannel(_ client:ClientHelper, channel:String){}
    func onSubscriptionFailedWithError(_ client:ClientHelper, error:subscriptionError){}
}

