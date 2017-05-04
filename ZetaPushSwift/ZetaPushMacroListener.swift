//
//  ZetaPushMacroListener.swift
//  ZetaPushSwift
//
//  Created by Mikael Morvan on 24/04/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//

import Foundation
import Gloss

open class ZetaPushMacroListener{
    
    var clientHelper: ClientHelper?
    public var zetaPushMacroService: ZetaPushMacroService
    open var onMacroError : ZPMacroServiceErrorBlock?
    
    public init(_ clientHelper: ClientHelper, deploymentId: String){
        self.clientHelper = clientHelper
        self.zetaPushMacroService = ZetaPushMacroService(clientHelper, deploymentId: deploymentId)
        self.register()
    }
    // Must be overriden by descendants
    open func register(){}
    
    public convenience init(_ clientHelper: ClientHelper){
        self.init(clientHelper, deploymentId: zetaPushDefaultConfig.macroDeployementId)
    }
    
    /*
     Generic Subscribe with a Generic parameter
     */
    public func subscribe<T: Glossy>(verb: String, callback: @escaping (T)->Void) {
        
        let channelBlockServiceCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
            
            if messageDict.object(forKey: "errors") != nil {
                if let errors = messageDict["errors"] as? NSArray {
                    if errors.count > 0 {
                        if let error = errors[0] as? NSDictionary {
                            self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.genericFromDictionnary(error))
                        } else {
                            self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.unknowError)
                        }
                    }
                }
            }
            
            if let result = messageDict["result"] as? NSDictionary {
                
                guard let zpMessage = T(json: result as! JSON) else {
                    
                    self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.decodingError)
                    return
                }
                
                callback(zpMessage)
            }
            
        }
        
        _ = self.clientHelper?.subscribe((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.zetaPushMacroService.deploymentId!))!, block: channelBlockServiceCall)
        
    }
    
    /*
     Generic Subscribe with a Generic parameter
     */
    public func subscribe<T: AbstractMacroCompletion>(verb: String, callback: @escaping (T)->Void) {
        
        let channelBlockServiceCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
            
            if messageDict.object(forKey: "errors") != nil {
                if let errors = messageDict["errors"] as? NSArray {
                    if errors.count > 0 {
                        if let error = errors[0] as? NSDictionary {
                            self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.genericFromDictionnary(error))
                        } else {
                            self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.unknowError)
                        }
                    }
                }
            }
            
            if let result = messageDict["result"] as? NSDictionary {
                
                guard let zpMessage = T.resultType(json: result as! JSON) else {
                    
                    self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.decodingError)
                    return
                }
                
                let completion = T(result: zpMessage, name: verb, requestId: "")
                
                callback(completion)
            }
            
        }
        
        _ = self.clientHelper?.subscribe((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.zetaPushMacroService.deploymentId!))!, block: channelBlockServiceCall)
        
    }
    
    /*
     Generic Subscribe with a Generic Array parameter
     */
    public func subscribe<T: Glossy>(verb: String, callback: @escaping ([T])->Void) {
        
        let channelBlockServiceCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
            
            if messageDict.object(forKey: "errors") != nil {
                if let errors = messageDict["errors"] as? NSArray {
                    if errors.count > 0 {
                        if let error = errors[0] as? NSDictionary {
                            self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.genericFromDictionnary(error))
                        } else {
                            self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.unknowError)
                        }
                    }
                }
            }
        
        
            if let result = messageDict["result"] as? NSDictionary {
                guard let zpMessage = [T].from(jsonArray: result.allKeys as! [JSON]) else {
                    
                    self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.decodingError)
                    return
                }
                
                callback(zpMessage)
            }
            
        }
        
        _ = self.clientHelper?.subscribe((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.zetaPushMacroService.deploymentId!))!, block: channelBlockServiceCall)
        
    }
    
    /*
        Generic Subscribe with a NSDictionary parameter
     */
    public func subscribe(verb: String, callback: @escaping (NSDictionary)->Void) {
        
        let channelBlockServiceCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
            
            if messageDict.object(forKey: "errors") != nil {
                if let errors = messageDict["errors"] as? NSArray {
                    if errors.count > 0 {
                        if let error = errors[0] as? NSDictionary {
                            self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.genericFromDictionnary(error))
                        } else {
                            self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.unknowError)
                        }
                    }
                }
            }
            
            if let result = messageDict["result"] as? NSDictionary {
                
                callback(result)
            }
            
        }
        
        _ = self.clientHelper?.subscribe((self.clientHelper?.composeServiceChannel(verb, deploymentId: self.zetaPushMacroService.deploymentId!))!, block: channelBlockServiceCall)
        
    }
    
}
