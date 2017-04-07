//
//  ZetaPushServiceDelegate.swift
//  Pods
//
//  Created by Morvan Mikaël on 30/03/2017.
//
//

import Foundation

public protocol ZetaPushServiceDelegate: NSObjectProtocol {
    func onDidSubscribeToChannel(_ client:ClientHelper, channel:String)
    func onDidUnsubscribeFromChannel(_ client:ClientHelper, channel:String)
    func onSubscriptionFailedWithError(_ client:ClientHelper, error:subscriptionError)
}

public extension ZetaPushServiceDelegate {
    func onDidSubscribeToChannel(_ client:ClientHelper, channel:String){}
    func onDidUnsubscribeFromChannel(_ client:ClientHelper, channel:String){}
    func onSubscriptionFailedWithError(_ client:ClientHelper, error:subscriptionError){}
}
