//
//  ZetaPushMacroListener.swift
//  ZetaPushSwift
//
//  Created by Mikael Morvan on 24/04/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//

import Foundation
import Gloss

open class ZetaPushMacroListener {
    
    public let clientHelper: ClientHelper
    public var zetaPushMacroService: ZetaPushMacroService
    open var onMacroError : ZPMacroServiceErrorBlock?
    
    public init(_ clientHelper: ClientHelper, deploymentId: String) {
        self.clientHelper = clientHelper
        self.zetaPushMacroService = ZetaPushMacroService(clientHelper, deploymentId: deploymentId)
        self.register()
    }

    // Must be overriden by descendants
    open func register() {}

    public convenience init(_ clientHelper: ClientHelper) {
        self.init(clientHelper, deploymentId: zetaPushDefaultConfig.macroDeployementId)
    }
    /**
     
     */
    public func getModelBlock<T: Glossy>(verb: String, callback: @escaping (T) -> Void) -> ModelBlockTuple {
        let channel = self.clientHelper.composeServiceChannel(verb, deploymentId: self.zetaPushMacroService.deploymentId!)
        let model = CometdSubscriptionModel(subscriptionUrl: channel, clientId: self.clientHelper.cometdClient.cometdClientId)
        return ModelBlockTuple(model: model, block: { (messageDict: NSDictionary) -> Void in

            self.handleMacroErrors(from: messageDict)
            guard let zpMessage: T = self.parse(messageDict: messageDict) else {
                self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.decodingError)
                return
            }
            callback(zpMessage)
        })
    }

    public func getModelBlock<T: Glossy>(verb: String, callback: @escaping ([T]) -> Void) -> ModelBlockTuple {
        let channel = self.clientHelper.composeServiceChannel(verb, deploymentId: self.zetaPushMacroService.deploymentId!)
        let model = CometdSubscriptionModel(subscriptionUrl: channel, clientId: self.clientHelper.cometdClient.cometdClientId)
        return ModelBlockTuple(model: model, block: {(messageDict: NSDictionary) -> Void in

            self.handleMacroErrors(from: messageDict)
            guard let zpMessage: [T] = self.parse(messageDict: messageDict) else {
                self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.decodingError)
                return
            }
            callback(zpMessage)
        })
    }

    public func getModelBlock<T: AbstractMacroCompletion>(verb: String, callback: @escaping (T) -> Void) -> ModelBlockTuple {
        let channel = self.clientHelper.composeServiceChannel(verb, deploymentId: self.zetaPushMacroService.deploymentId!)
        let model = CometdSubscriptionModel(subscriptionUrl: channel, clientId: self.clientHelper.cometdClient.cometdClientId)
        return ModelBlockTuple(model: model, block: {(messageDict: NSDictionary) -> Void in
            
            self.handleMacroErrors(from: messageDict)
            guard let zpMessage: T = self.parse(messageDict: messageDict, verb: verb) else {
                self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.decodingError)
                return
            }
            callback(zpMessage)
        })
    }

    public func getModelBlock<T: NSDictionary>(verb: String, callback: @escaping (T) -> Void) -> ModelBlockTuple {
        let channel = self.clientHelper.composeServiceChannel(verb, deploymentId: self.zetaPushMacroService.deploymentId!)
        let model = CometdSubscriptionModel(subscriptionUrl: channel, clientId: self.clientHelper.cometdClient.cometdClientId)
        return ModelBlockTuple(model: model, block: {(messageDict: NSDictionary) -> Void in
            
            self.handleMacroErrors(from: messageDict)
            guard let zpMessage: T = self.parse(messageDict: messageDict) else {
                self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.decodingError)
                return
            }
            callback(zpMessage)

        })
    }

    
    public func subscribe(_ tuples: [ModelBlockTuple]) {
        self.clientHelper.subscribe(tuples)
    }
    
    /// Generic Subscribe with a Generic parameter
    public func subscribe<T: Glossy>(verb: String, callback: @escaping (T) -> Void) {
        
        let channelBlockServiceCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
            
            self.handleMacroErrors(from: messageDict)
            guard let zpMessage: T = self.parse(messageDict: messageDict) else {
                self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.decodingError)
                return
            }
            callback(zpMessage)
        }
        let channel: String = self.clientHelper.composeServiceChannel(verb, deploymentId: self.zetaPushMacroService.deploymentId!)
        self.clientHelper.subscribe(channel, block: channelBlockServiceCall)
        
    }
    
    /// Generic Subscribe with a Generic parameter
    public func subscribe<T: AbstractMacroCompletion>(verb: String, callback: @escaping (T) -> Void) {
        
        let channelBlockServiceCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
            
            self.handleMacroErrors(from: messageDict)
            guard let zpMessage: T = self.parse(messageDict: messageDict, verb: verb) else {
                self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.decodingError)
                return
            }
            callback(zpMessage)
        }
        let channel: String = self.clientHelper.composeServiceChannel(verb, deploymentId: self.zetaPushMacroService.deploymentId!)
        self.clientHelper.subscribe(channel, block: channelBlockServiceCall)
        
    }
    
    /// Generic Subscribe with a Generic Array parameter
    public func subscribe<T: Glossy>(verb: String, callback: @escaping ([T]) -> Void) {
        let channelBlockServiceCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
            
            self.handleMacroErrors(from: messageDict)
            guard let zpMessage: [T] = self.parse(messageDict: messageDict) else {
                self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.decodingError)
                return
            }
            callback(zpMessage)
        }
        
        let channel: String = self.clientHelper.composeServiceChannel(verb, deploymentId: self.zetaPushMacroService.deploymentId!)
        self.clientHelper.subscribe(channel, block: channelBlockServiceCall)
        
    }
    
    /// Generic Subscribe with a NSDictionary parameter
    public func subscribe<T: NSDictionary>(verb: String, callback: @escaping (T) -> Void) {
        let channelBlockServiceCall:ChannelSubscriptionBlock = {(messageDict) -> Void in
            
            self.handleMacroErrors(from: messageDict)
            guard let zpMessage: T = self.parse(messageDict: messageDict) else {
                self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.decodingError)
                return
            }
            callback(zpMessage)

        }
        
        let channel: String = self.clientHelper.composeServiceChannel(verb, deploymentId: self.zetaPushMacroService.deploymentId!)
        self.clientHelper.subscribe(channel, block: channelBlockServiceCall)
        
    }
    
    // MARK: - private funcs
    private func handleMacroErrors(from messageDict: NSDictionary) {
        if let errors = messageDict["errors"] as? NSArray, messageDict.object(forKey: "errors") != nil && errors.count > 0 {
            if let error = errors[0] as? NSDictionary {
                self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.genericFromDictionnary(error))
            } else {
                self.onMacroError?(self.zetaPushMacroService, ZetaPushMacroError.unknowError)
            }
        }
    }
    
    private func parse<T: Glossy>(messageDict: NSDictionary) -> T? {
        guard let result = messageDict["result"] as? NSDictionary,
            let zpMessage = T(json: result as! JSON) else {
                return nil
        }
        return zpMessage
    }
    
    private func parse<T: Glossy>(messageDict: NSDictionary) -> [T]? {
        guard let result = messageDict["result"] as? NSDictionary,
            let zpMessage = [T].from(jsonArray: result.allKeys as! [JSON]) else {
                return nil
        }
        return zpMessage
    }
    
    private func parse<T: AbstractMacroCompletion>(messageDict: NSDictionary, verb: String) -> T? {
        guard let result = messageDict["result"] as? NSDictionary,
            let zpMessage = T.resultType(json: result as! JSON) else {
                return nil
        }
        return T(result: zpMessage, name: verb, requestId: "")
    }
    
    private func parse<T: NSDictionary>(messageDict: NSDictionary) -> T? {
        guard let zpMessage = messageDict["result"] as? T else {
                return nil
        }
        return zpMessage
    }
}
