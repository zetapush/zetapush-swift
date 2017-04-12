//
//  ZetaPushMacroService.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 04/04/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//

/*
    Macro Service
 
    Use his own subscription list to handle generic /completed channel when we call a macro with hardfail = true
 
    For the promise asyncCall function, the global (cometD) subscription list is used
 */
import Foundation
import PromiseKit

enum ZetaPushMacroError: Error {
    case genericError(errorCode: String, errorMessage: String)
    case unknowError
}

open class ZetaPushMacroService : NSObject {
    
    open var onMacroError : ((_ zetaPushMacroService : ZetaPushMacroService, _ macroName: String, _ errorMessage : String, _ errorCode : String, _ errorLocation : String)->())?
    
    var clientHelper: ClientHelper?
    var deploymentId: String?
    var macroChannel: String?
    var macroChannelError: String?
    
    var channelSubscriptionBlocks = Dictionary<String, Array<Subscription>>()
    
    
    // Callback for /completed macro channel
    lazy var channelBlockMacroCompleted:ChannelSubscriptionBlock = {(messageDict) -> Void in
        
        print("ZetaPushMacroService channelBlockMacroCompleted", messageDict, messageDict["name"] as Any)
        
        let macroChannel = self.composeServiceChannel(messageDict["name"] as! String)
        if let result = messageDict["result"] as? NSDictionary {
            if let channelBlock = self.channelSubscriptionBlocks[macroChannel] {
                for channel in channelBlock {
                    channel.callback!(result)
                }
            }
        }
    }
    
    // Callback for /error macro channel
    lazy var channelBlockMacroError:ChannelSubscriptionBlock = {(messageDict) -> Void in
        print("ZetaPushMacroService channelBlockMacroError", messageDict)
        
        let errorCode = messageDict["code"] as! String
        let errorMessage = messageDict["message"] as! String
        let errorLocation = messageDict["location"] as! String
        let source: AnyObject = messageDict["source"] as AnyObject
        let data: AnyObject = source["data"] as AnyObject
        let macroName = data["name"] as! String
        
        self.onMacroError?(self, macroName, errorMessage, errorCode, errorLocation)
    }
    
    public init(_ clientHelper: ClientHelper, deploymentId: String){
        self.clientHelper = clientHelper
        self.deploymentId = deploymentId
        super.init()
        
        // Subscribe to completed macro channel
        self.macroChannel = "/service/" + self.clientHelper!.getSandboxId() + "/" + self.deploymentId! + "/" + "completed"
        _ = self.clientHelper?.subscribe(self.macroChannel!, block: channelBlockMacroCompleted)
        
        self.macroChannelError = "/service/" + self.clientHelper!.getSandboxId() + "/" + self.deploymentId! + "/" + "error"
        _ = self.clientHelper?.subscribe(self.macroChannelError!, block: channelBlockMacroError)
        
        self.clientHelper?.onDidSubscribeToChannel = {client, channel in
            print("ZetaPushMacroService zetaPushClient.onDidSubscribeToChannel", channel)
        }
        self.clientHelper?.onDidUnsubscribeToChannel = {client, channel in
            print("ZetaPushMacroService zetaPushClient.onDidUnsubscribeToChannel", channel)
        }
    }
    
    public convenience init(_ clientHelper: ClientHelper){
        self.init(clientHelper, deploymentId: zetaPushDefaultConfig.macroDeployementId)
    }
    
    private func composeServiceChannel(_ verb: String) -> String {
        return "/service/" + self.clientHelper!.getSandboxId() + "/" + self.deploymentId! + "/" + verb
    }
    
    open func subscribe(verb: String, block:ChannelSubscriptionBlock?=nil) -> Subscription {
        
        let subscribedChannel = composeServiceChannel(verb)
        var sub = Subscription(callback:nil, channel: subscribedChannel, id: 0)
        if let block = block {
            if self.channelSubscriptionBlocks[subscribedChannel] == nil
            {
                self.channelSubscriptionBlocks[subscribedChannel] = []
            }
            // Create a structure to store the callback and the id of 
            sub.callback = block
            sub.id = self.channelSubscriptionBlocks[subscribedChannel]!.count
            self.channelSubscriptionBlocks[subscribedChannel]!.append(sub)
        }
                
        return sub
    }
    
    open func unsubscribe(_ subscription:Subscription){
        var subscriptionArray = self.channelSubscriptionBlocks[subscription.channel]
        if let index = subscriptionArray?.index(of: subscription){
            subscriptionArray?.remove(at: index)
        }
        if subscriptionArray?.count == 0 {
            self.channelSubscriptionBlocks[subscription.channel] = nil;
        }
    }
    
    open func call(verb:String, parameters:[String:AnyObject]) {
        let dict:[String:AnyObject] = [
            "name": verb as AnyObject,
            "hardFail": true as AnyObject,
            "parameters": parameters as AnyObject
        ]
        self.clientHelper?.publish(composeServiceChannel("call"), message: dict)
    }
    
    /*
        asynCall return a promise
     */
    open func asyncCall(verb:String, parameters:[String:AnyObject]) -> Promise<NSDictionary> {
        return Promise { fulfill, reject in
            let requestId = UUID().uuidString
            
            let dict:[String:AnyObject] = [
                "name": verb as AnyObject,
                "hardFail": false as AnyObject,
                "parameters": parameters as AnyObject,
                "requestId": requestId as AnyObject
            ]
            
            var sub: Subscription? = nil
            
            let channelBlockMacroCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
                
                // Check if the requestId is similar to the one sent
                if messageDict.object(forKey: "requestId") != nil {
                    if let msgRequestId = messageDict["requestId"] as? String {
                        if msgRequestId != requestId {
                            return
                        }
                    }
                }
                
                self.clientHelper?.unsubscribe(sub!)
                
                if let result = messageDict["result"] as? NSDictionary {
                    fulfill(result)
                }
                if messageDict.object(forKey: "errors") != nil {
                    if let errors = messageDict["errors"] as? NSArray {
                        if errors.count > 0 {
                             if let error = errors[0] as? NSDictionary {
                             let errorCode = error["code"] as? String
                             let errorMessage = error["message"] as? String
                             
                             reject(ZetaPushMacroError.genericError(errorCode: errorCode!, errorMessage: errorMessage!))
                             } else {
                             reject(ZetaPushMacroError.unknowError)
                             }
                        }
                    }
                }
                
            }
            
            sub = self.clientHelper?.subscribe(composeServiceChannel(verb), block: channelBlockMacroCall)
 
            self.clientHelper?.publish(composeServiceChannel("call"), message: dict)
            
        }
    }
    
    open func asyncCallGeneric<T : ZPMessage, U: ZPMessage>(verb:String, parameters:T) -> Promise<U> {
        return Promise { fulfill, reject in
            
            let requestId = UUID().uuidString
            
            let dict:[String:AnyObject] = [
                "name": verb as AnyObject,
                "hardFail": false as AnyObject,
                "parameters": parameters.toDict(),
                "requestId": requestId as AnyObject
            ]
            
            var sub: Subscription? = nil
            
            let channelBlockMacroCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
                // Check if the requestId is similar to the one sent
                if messageDict.object(forKey: "requestId") != nil {
                    if let msgRequestId = messageDict["requestId"] as? String {
                        if msgRequestId != requestId {
                            return
                        }
                    }
                }
                
                self.clientHelper?.unsubscribe(sub!)
                
                if let result = messageDict["result"] as? NSDictionary {
                    
                    let zpMessage = U()
                    zpMessage.fromDict(result)
                    
                    fulfill(zpMessage)
                }
                if messageDict.object(forKey: "errors") != nil {
                    if let errors = messageDict["errors"] as? NSArray {
                        if errors.count > 0 {
                            if let error = errors[0] as? NSDictionary {
                                let errorCode = error["code"] as? String
                                let errorMessage = error["message"] as? String
                                
                                reject(ZetaPushMacroError.genericError(errorCode: errorCode!, errorMessage: errorMessage!))
                            } else {
                                reject(ZetaPushMacroError.unknowError)
                            }
                        }
                    }
                }
                
            }
            
            sub = self.clientHelper?.subscribe(composeServiceChannel(verb), block: channelBlockMacroCall)
            
            self.clientHelper?.publish(composeServiceChannel("call"), message: dict)
            
        }
    }
    
}

open class ZetaPushMacroPublisher{
    
    var clientHelper: ClientHelper?
    public var zetaPushMacroService: ZetaPushMacroService
    
    public init(_ clientHelper: ClientHelper, deploymentId: String){
        self.clientHelper = clientHelper
        self.zetaPushMacroService = ZetaPushMacroService(clientHelper, deploymentId: deploymentId)
    }
    
    public convenience init(_ clientHelper: ClientHelper){
        self.init(clientHelper, deploymentId: zetaPushDefaultConfig.macroDeployementId)
    }
    
    public func genericSubscribe<T: ZPMessage>(verb: String, type: T.Type, callback: @escaping ZPChannelSubscriptionBlock) {
        
        let channelBlockServiceCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
            
            if let result = messageDict["result"] as? NSDictionary {
                let zpMessage = T()
                zpMessage.fromDict(result)
                
                callback(zpMessage)
            }
            /* TODO Handle Errors
            if messageDict.object(forKey: "errors") != nil {
                if let errors = messageDict["errors"] as? NSArray {
                    if errors.count > 0 {
                        if let error = errors[0] as? NSDictionary {
                            let errorCode = error["code"] as? String
                            let errorMessage = error["message"] as? String
                            
                            reject(ZetaPushMacroError.genericError(errorCode: errorCode!, errorMessage: errorMessage!))
                        } else {
                            reject(ZetaPushMacroError.unknowError)
                        }
                    }
                }
            }
            */
            
            
        }
        
        _ = self.clientHelper?.subscribe((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.zetaPushMacroService.deploymentId!))!, block: channelBlockServiceCall)
        
    }
}
