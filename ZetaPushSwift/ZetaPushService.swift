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
    
    
    //let log = XCGLogger(identifier: "serviceLogger", includeDefaultDestinations: true)
    
    public init(_ clientHelper: ClientHelper, deploymentId: String){
        self.clientHelper = clientHelper
        self.deploymentId = deploymentId
        
        super.init()
        
    }
    
    open func subscribe(verb: String, block:ChannelSubscriptionBlock?=nil) -> Subscription{
        
        let subscribedChannel = self.clientHelper?.composeServiceChannel(verb, deploymentId: self.deploymentId!)
        
        return self.clientHelper!.subscribe(subscribedChannel!, block: block)
    }
    
    open func unsubscribe(_ subscription:Subscription){
        self.clientHelper?.unsubscribe(subscription)
    }
    
    open func publish(verb:String, parameters:[String:AnyObject]) {
        
        clientHelper?.publish((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.deploymentId!))!, message: parameters)
    }
    
    open func asyncPublish(verb:String, parameters:[String:AnyObject]) -> Promise<NSDictionary> {
        return Promise { fulfill, reject in
            
            var sub: Subscription? = nil
            var subError: Subscription? = nil
            
            let channelBlockServiceCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
                self.clientHelper?.unsubscribe(sub!)
                self.clientHelper?.unsubscribe(subError!)
                
                fulfill(messageDict)
                
            }
            
            let channelBlockServiceError:ChannelSubscriptionBlock = {(messageDict) -> Void in
                self.clientHelper?.unsubscribe(sub!)
                self.clientHelper?.unsubscribe(subError!)
                
                
                let errorCode = messageDict["code"] as? String
                let errorMessage = messageDict["message"] as? String
                let errorSource = messageDict["source"] as? NSDictionary
                
                reject(ZetaPushServiceError.genericError(errorCode: errorCode!, errorMessage: errorMessage!, errorSource: errorSource!))
                
            }
            
            sub = self.clientHelper?.subscribe((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.deploymentId!))!, block: channelBlockServiceCall)
            subError = self.clientHelper?.subscribe((self.clientHelper?.composeServiceChannel("error", deploymentId: self.deploymentId!))!, block: channelBlockServiceError)
            
            self.clientHelper?.publish((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.deploymentId!))!, message: parameters)
        }
    }
    
    open func asyncPublishGeneric<T : ZPMessage, U: ZPMessage>(verb:String, parameters:T) -> Promise<U> {
        return Promise { fulfill, reject in
            
            var sub: Subscription? = nil
            var subError: Subscription? = nil
            
            let channelBlockServiceCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
                self.clientHelper?.unsubscribe(sub!)
                self.clientHelper?.unsubscribe(subError!)
                
                let zpMessage = U()
                zpMessage.fromDict(messageDict)

                fulfill(zpMessage)
                
            }
            
            let channelBlockServiceError:ChannelSubscriptionBlock = {(messageDict) -> Void in
                self.clientHelper?.unsubscribe(sub!)
                self.clientHelper?.unsubscribe(subError!)
                
                
                let errorCode = messageDict["code"] as? String
                let errorMessage = messageDict["message"] as? String
                let errorSource = messageDict["source"] as? NSDictionary
                
                reject(ZetaPushServiceError.genericError(errorCode: errorCode!, errorMessage: errorMessage!, errorSource: errorSource!))
                
            }
            
            sub = self.clientHelper?.subscribe((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.deploymentId!))!, block: channelBlockServiceCall)
            subError = self.clientHelper?.subscribe((self.clientHelper?.composeServiceChannel("error", deploymentId: self.deploymentId!))!, block: channelBlockServiceError)
            let param = parameters.toDict() as! [String: AnyObject]
            self.clientHelper?.publish((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.deploymentId!))!, message: param)
        }
    }
}

open class ZetaPushServicePublisher{
    
    var clientHelper: ClientHelper?
    public var zetaPushService: ZetaPushService
    
    public init(_ clientHelper: ClientHelper, deploymentId: String){
        self.clientHelper = clientHelper
        self.zetaPushService = ZetaPushService(clientHelper, deploymentId: deploymentId)
    }
    
    public func genericSubscribe<T: ZPMessage>(verb: String, type: T.Type, callback: @escaping ZPChannelSubscriptionBlock) {
    
        let channelBlockServiceCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
    
            let zpMessage = T()
            zpMessage.fromDict(messageDict)
    
            callback(zpMessage)
    
        }
        
        _ = self.clientHelper?.subscribe((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.zetaPushService.deploymentId!))!, block: channelBlockServiceCall)
    
    
    }
}
