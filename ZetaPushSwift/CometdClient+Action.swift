//
//  CometdClient+Action.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 23/03/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

import Foundation

extension CometdClient {
    
    // MARK: Private - Timer Action
    @objc
    func pendingSubscriptionsAction(_ timer: Timer) {
        guard cometdConnected == true else {
            log.error("Cometd: Failed to resubscribe to all pending channels, socket disconnected")
            
            return
        }
        
        resubscribeToPendingSubscriptions()
    }
}
