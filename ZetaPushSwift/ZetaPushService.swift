//
//  ZetaPushService.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 04/04/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//

import Foundation
import PromiseKit

enum ZetaPushServiceError: Error {
    case genericError(errorCode: String, errorMessage: String, errorSource: NSDictionary)
    case unknowError
}

open class ZetaPushService : NSObject {
    
    var clientHelper: ClientHelper?
    var deploymentId: String?
    
    public init(_ clientHelper: ClientHelper, deploymentId: String){
        self.clientHelper = clientHelper
        self.deploymentId = deploymentId
        
        super.init()
        
    } 
    
    private func composeServiceChannel(_ verb: String) -> String {
        return "/service/" + self.clientHelper!.getSandboxId() + "/" + self.deploymentId! + "/" + verb
    }
    
    open func subscribe(verb: String, block:ChannelSubscriptionBlock?=nil) -> Subscription{
        
        let subscribedChannel = composeServiceChannel(verb)
        
        return self.clientHelper!.subscribe(subscribedChannel, block: block)
    }
    
    open func unsubscribe(_ subscription:Subscription){
        self.clientHelper?.unsubscribe(subscription)
    }
    
    open func publish(verb:String, parameters:[String:AnyObject]) {
        
        clientHelper?.publish(composeServiceChannel(verb), message: parameters)
    }
    
    open func asyncPublish(verb:String, parameters:[String:AnyObject]) -> Promise<NSDictionary> {
        return Promise { fullfill, reject in
            
            var sub: Subscription? = nil
            var subError: Subscription? = nil
            
            let channelBlockServiceCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
                self.clientHelper?.unsubscribe(sub!)
                self.clientHelper?.unsubscribe(subError!)
                
                fullfill(messageDict)
                
            }
            
            let channelBlockServiceError:ChannelSubscriptionBlock = {(messageDict) -> Void in
                self.clientHelper?.unsubscribe(sub!)
                self.clientHelper?.unsubscribe(subError!)
                
                
                let errorCode = messageDict["code"] as? String
                let errorMessage = messageDict["message"] as? String
                let errorSource = messageDict["source"] as? NSDictionary
                
                reject(ZetaPushServiceError.genericError(errorCode: errorCode!, errorMessage: errorMessage!, errorSource: errorSource!))
                
            }
            
            sub = self.clientHelper?.subscribe(composeServiceChannel(verb), block: channelBlockServiceCall)
            subError = self.clientHelper?.subscribe(composeServiceChannel("error"), block: channelBlockServiceError)
            
            self.clientHelper?.publish(composeServiceChannel(verb), message: parameters)
        }
    }
}
