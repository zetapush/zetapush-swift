//
//  ZetaPushClient.swift
//  Pods
//
//  Created by Morvan Mikaël on 28/03/2017.
//
//

import Foundation

struct zetaPushDefaultConfig {
    static let apiUrl = "https://api.zpush.io"
    static let weakDeploymentId = "weak_0"
    static let simpleDeploymentId = "simple_0"
    static let macroDeployementId = "macro_0"
    static let resourceLength = 8
}
struct zetaPushDefaultKeys{
    static let sandboxId = "zetapush.sandboxId"
    static let token = "zetapush.token"
    static let publicToken = "zetapush.publicToken"
    static let resource = "zetapush.resource"
}

public typealias ZPChannelSubscriptionBlock = (ZPMessage) -> Void

/*
 Generic (useless) client for ZetaPush
 Use Weak or Smart client instead
 */
open class ZetaPushClient: ClientHelper {
    

}


open class ZPMessage {
    
    required public init () {
        
    }
    
    open func toDict() -> NSDictionary {
        preconditionFailure("This method must be overridden")
    }
    
    open func fromDict(_ dict : NSDictionary) {
        preconditionFailure("This method must be overridden")
    }
    
}

open class ZetaPushUtils {
    class func generateResourceName() -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< zetaPushDefaultConfig.resourceLength {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
}
