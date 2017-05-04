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
import XCGLogger
import Gloss

public protocol AbstractMacroCompletion{
    associatedtype resultType:Glossy
    init(result: resultType, name: String, requestId: String)
    var name: String { get set }
    var requestId: String { get set }
    var result: resultType { get set }
}
// Dummy class
public struct EmptyMessage: Glossy {
    let empty: String?
    
    public init?(json: JSON) {
        self.empty = "empty" <~~ json
    }
    
    public func toJSON() -> JSON? {
        return jsonify([
            "empty" ~~> self.empty
            ])
    }
}

public enum ZetaPushMacroError: Error {
    case genericError(macroName: String, errorMessage: String, errorCode: String, errorLocation: String)
    case unknowError
    case decodingError
    
    static func genericFromDictionnary(_ messageDict: NSDictionary) -> ZetaPushMacroError {
        
        let errorCode = ZetaPushUtils.getStringIfExistsFromNSDictionnary(key: "code", dict: messageDict)
        let errorMessage = ZetaPushUtils.getStringIfExistsFromNSDictionnary(key: "message", dict: messageDict)
        let errorLocation = ZetaPushUtils.getStringIfExistsFromNSDictionnary(key: "location", dict: messageDict)
        var macroName = ""
        if messageDict.object(forKey: "source") != nil {
            let source: AnyObject = messageDict["source"] as AnyObject
            let data: AnyObject = source["data"] as AnyObject
            macroName = data["name"] as! String
        }
            
        return ZetaPushMacroError.genericError(macroName: macroName, errorMessage: errorMessage, errorCode: errorCode, errorLocation: errorLocation)
    }
}

open class ZetaPushMacroService : NSObject {
    
    open var onMacroError : ZPMacroServiceErrorBlock?
    
    var clientHelper: ClientHelper?
    var deploymentId: String?
    var macroChannel: String?
    var macroChannelError: String?
    
    var channelSubscriptionBlocks = Dictionary<String, Array<Subscription>>()
    
    let log = XCGLogger(identifier: "macroserviceLogger", includeDefaultDestinations: true)
    
    // Callback for /completed macro channel
    lazy var channelBlockMacroCompleted:ChannelSubscriptionBlock = {(messageDict) -> Void in
        
        self.log.debug("ZetaPushMacroService channelBlockMacroCompleted")
        self.log.debug(messageDict)
        
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
        self.log.debug("ZetaPushMacroService channelBlockMacroError")
        self.log.debug(messageDict)
        
        self.onMacroError?(self, ZetaPushMacroError.genericFromDictionnary(messageDict))
    }
    
    public init(_ clientHelper: ClientHelper, deploymentId: String){
        self.clientHelper = clientHelper
        self.deploymentId = deploymentId
        super.init()
        
        self.log.setup(level: (self.clientHelper?.getLogLevel())!)
        
        // Subscribe to completed macro channel
        self.macroChannel = "/service/" + self.clientHelper!.getSandboxId() + "/" + self.deploymentId! + "/" + "completed"
        _ = self.clientHelper?.subscribe(self.macroChannel!, block: channelBlockMacroCompleted)
        
        self.macroChannelError = "/service/" + self.clientHelper!.getSandboxId() + "/" + self.deploymentId! + "/" + "error"
        _ = self.clientHelper?.subscribe(self.macroChannelError!, block: channelBlockMacroError)
        
        self.clientHelper?.onDidSubscribeToChannel = {client, channel in
            self.log.debug("ZetaPushMacroService zetaPushClient.onDidSubscribeToChannel \(channel)")
        }
        self.clientHelper?.onDidUnsubscribeToChannel = {client, channel in
            self.log.debug("ZetaPushMacroService zetaPushClient.onDidUnsubscribeToChannel \(channel)")
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
    
    open func call(verb:String, parameters:NSDictionary) {
        let dict:[String:AnyObject] = [
            "name": verb as AnyObject,
            "hardFail": true as AnyObject,
            "parameters": parameters
        ]
        self.clientHelper?.publish(composeServiceChannel("call"), message: dict)
    }
    
    /*
        Call return a promise
     */
    open func call(verb:String, parameters:[String:AnyObject]) -> Promise<NSDictionary> {
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
                                reject(ZetaPushMacroError.genericFromDictionnary(error))
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
    
    open func call<T : Glossy, U: AbstractMacroCompletion>(verb:String, parameters:T) -> Promise<U> {
        return Promise { fulfill, reject in
            
            let requestId = UUID().uuidString
            
            let dict:[String:AnyObject] = [
                "name": verb as AnyObject,
                "hardFail": false as AnyObject,
                "parameters": parameters.toJSON() as AnyObject,
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
                    
                    guard let zpMessage = U.resultType(json: result as! JSON) else {
                        
                        reject(ZetaPushMacroError.decodingError)
                        
                        return
                    }
                    
                    let completion = U(result: zpMessage, name: verb, requestId: requestId)
                    
                    fulfill(completion)
                }
                if messageDict.object(forKey: "errors") != nil {
                    if let errors = messageDict["errors"] as? NSArray {
                        if errors.count > 0 {
                            if let error = errors[0] as? NSDictionary {
                                reject(ZetaPushMacroError.genericFromDictionnary(error))
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
    
    open func call<U: AbstractMacroCompletion>(verb:String) -> Promise<U> {
        return Promise { fulfill, reject in
            
            let requestId = UUID().uuidString
            
            let dict:[String:AnyObject] = [
                "name": verb as AnyObject,
                "hardFail": false as AnyObject,
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
                    
                    guard let zpMessage = U.resultType(json: result as! JSON) else {
                        
                        reject(ZetaPushMacroError.decodingError)
                        
                        return
                    }
                    
                    let completion = U(result: zpMessage, name: verb, requestId: requestId)
                    
                    fulfill(completion)
                }
                if messageDict.object(forKey: "errors") != nil {
                    if let errors = messageDict["errors"] as? NSArray {
                        if errors.count > 0 {
                            if let error = errors[0] as? NSDictionary {
                                reject(ZetaPushMacroError.genericFromDictionnary(error))
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
    
    open func call<T: Glossy>(verb:String, parameters:T) {
        let dict:[String:AnyObject] = [
            "name": verb as AnyObject,
            "hardFail": true as AnyObject,
            "parameters": parameters.toJSON() as AnyObject
        ]
        self.clientHelper?.publish(composeServiceChannel("call"), message: dict)
    }
    
    open func call(verb:String) {
        let dict:[String:AnyObject] = [
            "name": verb as AnyObject,
            "hardFail": true as AnyObject
        ]
        self.clientHelper?.publish(composeServiceChannel("call"), message: dict)
    }
    
    
    
}


