//
//  ZetaPushServiceListener.swift
//  ZetaPushSwift
//
//  Created by Mikael Morvan on 24/04/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//

import Foundation
import Gloss

open class ZetaPushServiceListener{
    var clientHelper: ClientHelper?
    var macroChannelError: String
    public var zetaPushService: ZetaPushService
    open var onServiceError: ZPServiceErrorBlock?
    
    // Callback for /error macro channel
    lazy var channelBlockMacroError:ChannelSubscriptionBlock = {(messageDict) -> Void in
        
        self.onServiceError?(self.zetaPushService, ZetaPushServiceError.genericFromDictionnary(messageDict))
    }
    
    open func register(){}
    
    public init(_ clientHelper: ClientHelper, deploymentId: String){
        self.clientHelper = clientHelper
        self.zetaPushService = ZetaPushService(clientHelper, deploymentId: deploymentId)
        
        self.macroChannelError = "/service/" + self.clientHelper!.getSandboxId() + "/" + deploymentId + "/" + "error"
        _ = self.clientHelper?.subscribe(self.macroChannelError, block: channelBlockMacroError)
        
        self.register()
    }
    
    public func genericSubscribe<T: Glossy>(verb: String, callback: @escaping (T)->Void) {
        
        let channelBlockServiceCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
            
            
            guard let zpMessage = T(json: messageDict as! JSON) else {
                
                self.onServiceError?(self.zetaPushService, ZetaPushServiceError.decodingError)
                return
            }
            
            callback(zpMessage)
            
        }
        
        _ = self.clientHelper?.subscribe((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.zetaPushService.deploymentId!))!, block: channelBlockServiceCall)
        
    }
    
}
