//
//  CometdClient+Helper.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 23/03/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

import Foundation

public extension CometdClient {
    
    // MARK: Helper
    
    ///  Validate whatever a subscription has been subscribed correctly
    public func isSubscribedToChannel(_ channel:String) -> Bool {
        return self.openSubscriptions.contains { $0.subscriptionUrl == channel }
    }
    
    ///  Validate cometd transport is connected
    public func isTransportConnected() -> Bool {
        return self.transport!.isConnected()
    }
}

