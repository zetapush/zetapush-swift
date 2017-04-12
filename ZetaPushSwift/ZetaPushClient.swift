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
}
struct zetaPushDefaultKeys{
    static let sandboxId = "zetapush.sandboxId"
    static let token = "zetapush.token"
    static let publicToken = "zetapush.publicToken"
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

