//
//  NsError+Helper.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 23/03/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

import Foundation

public enum CometdSocketError {
    case lostConnection, transportWrite
}

public extension NSError {
    
    // MARK:
    // MARK: Error
    
    /// Helper to create a error object for cometd realted issues
    convenience init(error: CometdSocketError) {
        self.init(domain: "com.hamin.cometdswift", code: 10000, userInfo: nil)
    }
}
