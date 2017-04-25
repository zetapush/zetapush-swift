//
//  ZetaPushService.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 04/04/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//

import Foundation
import PromiseKit
import XCGLogger
import Gloss

public enum ZetaPushServiceError: Error {
    case genericError(errorCode: String, errorMessage: String, errorSource: NSDictionary)
    case unknowError
    case decodingError
    
    static func genericFromDictionnary(_ messageDict: NSDictionary) -> ZetaPushServiceError {
        
        let errorCode = ZetaPushUtils.getStringIfExistsFromNSDictionnary(key: "code", dict: messageDict)
        let errorMessage = ZetaPushUtils.getStringIfExistsFromNSDictionnary(key: "message", dict: messageDict)
        let errorSource = ZetaPushUtils.getNSDictionnaryIfExistsFromNSDictionnary(key: "source", dict: messageDict)
        
        return ZetaPushServiceError.genericError(errorCode: errorCode, errorMessage: errorMessage, errorSource: errorSource!)
    }
}


open class ZetaPushService : NSObject {
    
    var clientHelper: ClientHelper?
    var deploymentId: String?
    
    let log = XCGLogger(identifier: "serviceLogger", includeDefaultDestinations: true)
    
    public init(_ clientHelper: ClientHelper, deploymentId: String){
        self.clientHelper = clientHelper
        self.deploymentId = deploymentId
        
        super.init()
        
        self.log.setup(level: (self.clientHelper?.getLogLevel())!)
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
                
                reject(ZetaPushServiceError.genericFromDictionnary(messageDict))
                
            }
            
            sub = self.clientHelper?.subscribe((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.deploymentId!))!, block: channelBlockServiceCall)
            subError = self.clientHelper?.subscribe((self.clientHelper?.composeServiceChannel("error", deploymentId: self.deploymentId!))!, block: channelBlockServiceError)
            
            self.clientHelper?.publish((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.deploymentId!))!, message: parameters)
        }
    }
    
    open func asyncPublishGeneric<T : Glossy, U: Glossy>(verb:String, parameters:T) -> Promise<U> {
        return Promise { fulfill, reject in
            
            var sub: Subscription? = nil
            var subError: Subscription? = nil
            
            let channelBlockServiceCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
                self.clientHelper?.unsubscribe(sub!)
                self.clientHelper?.unsubscribe(subError!)
                
                guard let zpMessage = U(json: messageDict as! JSON) else {
                    reject(ZetaPushServiceError.decodingError)
                    return
                }
                fulfill(zpMessage)
                
            }
            
            let channelBlockServiceError:ChannelSubscriptionBlock = {(messageDict) -> Void in
                self.clientHelper?.unsubscribe(sub!)
                self.clientHelper?.unsubscribe(subError!)
                
                reject(ZetaPushServiceError.genericFromDictionnary(messageDict))
                
            }
            
            sub = self.clientHelper?.subscribe((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.deploymentId!))!, block: channelBlockServiceCall)
            subError = self.clientHelper?.subscribe((self.clientHelper?.composeServiceChannel("error", deploymentId: self.deploymentId!))!, block: channelBlockServiceError)
            let param = parameters.toJSON()! as [String: AnyObject]
            self.clientHelper?.publish((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.deploymentId!))!, message: param)
        }
    }
    
    open func publishGeneric<T: Glossy>(verb:String, parameters:T) {
        clientHelper?.publish((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.deploymentId!))!, message: parameters.toJSON()! as [String:AnyObject])
    }
}


