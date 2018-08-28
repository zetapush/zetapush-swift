//
//  ZetaPushServiceListener.swift
//  ZetaPushSwift
//
//  Created by Mikael Morvan on 24/04/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//

import Foundation
import Gloss

public struct ModelBlockTuple {
    let model: CometdSubscriptionModel
    let block: ChannelSubscriptionBlock?
}

open class ZetaPushServiceListener{
    public var clientHelper: ClientHelper?
    var macroChannelError: String
    public var zetaPushService: ZetaPushService
    open var onServiceError: ZPServiceErrorBlock?
    
    // Callback for /error macro channel
    lazy var channelBlockMacroError:ChannelSubscriptionBlock = {(messageDict) -> Void in
        
        self.onServiceError?(self.zetaPushService, ZetaPushServiceError.genericFromDictionnary(messageDict))
    }
    
    // Must be overriden by descendants
    open func register(){}
    
    public init(_ clientHelper: ClientHelper, deploymentId: String){
        self.clientHelper = clientHelper
        self.zetaPushService = ZetaPushService(clientHelper, deploymentId: deploymentId)
        
        self.macroChannelError = "/service/" + self.clientHelper!.getSandboxId() + "/" + deploymentId + "/" + "error"
        _ = self.clientHelper?.subscribe(self.macroChannelError, block: channelBlockMacroError)
        
        self.register()
    }
    /**
     
     */
    public func getModelBlock<T: Glossy>(verb: String, callback: @escaping (T)->Void) -> ModelBlockTuple {
        let channel = (self.clientHelper?.composeServiceChannel(verb, deploymentId: self.zetaPushService.deploymentId!))!
        let model = CometdSubscriptionModel(subscriptionUrl: channel, clientId: self.clientHelper?.cometdClient?.cometdClientId)
        return ModelBlockTuple(model: model, block: {(messageDict: NSDictionary) -> Void in
            guard let zpMessage = T(json: messageDict as! JSON) else {
                
                self.onServiceError?(self.zetaPushService, ZetaPushServiceError.decodingError)
                return
            }
            callback(zpMessage)
        })
    }
    /**
     
     */
    public func subscribe(_ tuples: [ModelBlockTuple]) {
        _ = self.clientHelper?.subscribe(tuples);
    }
    /*
     Generic Subscribe with a Generic parameter
     */
    public func subscribe<T: Glossy>(verb: String, callback: @escaping (T)->Void) {
        
        let channelBlockServiceCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
            
            
            guard let zpMessage = T(json: messageDict as! JSON) else {
                
                self.onServiceError?(self.zetaPushService, ZetaPushServiceError.decodingError)
                return
            }
            
            callback(zpMessage)
            
        }
        
        _ = self.clientHelper?.subscribe((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.zetaPushService.deploymentId!))!, block: channelBlockServiceCall)
        
    }
    /*
     Generic Subscribe with a Generic Array parameter
     */
    public func subscribe<T: Glossy>(verb: String, callback: @escaping ([T])->Void) {
        
        let channelBlockServiceCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
            
            
            guard let zpMessage = [T].from(jsonArray: messageDict.allKeys as! [JSON]) else {
                
                self.onServiceError?(self.zetaPushService, ZetaPushServiceError.decodingError)
                return
            }
            
            callback(zpMessage)
            
        }
        
        _ = self.clientHelper?.subscribe((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.zetaPushService.deploymentId!))!, block: channelBlockServiceCall)
        
    }
    /*
     Generic Subscribe with a NSDictionary parameter
     */
    public func subscribe(verb: String, callback: @escaping (NSDictionary)->Void) {
        
        let channelBlockServiceCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
            
            callback(messageDict)
            
        }
        
        _ = self.clientHelper?.subscribe((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.zetaPushService.deploymentId!))!, block: channelBlockServiceCall)
        
    }
    
}
