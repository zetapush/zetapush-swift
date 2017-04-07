//
//  ZetaPushMacroService.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 04/04/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//

import Foundation

open class ZetaPushMacroService : NSObject {
    
    open var onMacroError : ((_ zetaPushMacroService : ZetaPushMacroService, _ macroName: String, _ errorMessage : String, _ errorCode : String, _ errorLocation : String)->())?
    
    var clientHelper: ClientHelper?
    var deploymentId: String?
    var macroChannel: String?
    var macroChannelError: String?
    
    var channelSubscriptionBlocks = Dictionary<String, Array<ChannelSubscriptionBlock>>()
    
    lazy var channelBlockMacroCompleted:ChannelSubscriptionBlock = {(messageDict) -> Void in
        
        print("ZetaPushMacroService channelBlockMacroCompleted", messageDict, messageDict["name"] as Any)
        
        let macroChannel = self.composeServiceChannel(messageDict["name"] as! String)
        let result: AnyObject = messageDict["result"] as AnyObject
        if let channelBlock = self.channelSubscriptionBlocks[macroChannel] {
            for channel in channelBlock {
                channel(result as! NSDictionary)
            }
        }
        
    }
    
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
    
    private func composeServiceChannel(_ verb: String) -> String {
        return "/service/" + self.clientHelper!.getSandboxId() + "/" + self.deploymentId! + "/" + verb
    }
    
    open func subscribe(verb: String, block:ChannelSubscriptionBlock?=nil) -> Subscription {
        
        let subscribedChannel = composeServiceChannel(verb)
        if let block = block {
            if self.channelSubscriptionBlocks[subscribedChannel] == nil
            {
                self.channelSubscriptionBlocks[subscribedChannel] = []
            }
            // Create a structure to store the callback and the id of 
            self.channelSubscriptionBlocks[subscribedChannel]!.append(block)
        }
                
        return self.clientHelper!.subscribe(subscribedChannel, block: channelBlockMacroCompleted)
    }
    
    open func unsubscribe(_ subscription:Subscription){
        self.clientHelper?.unsubscribe(subscription)
    }
    
    open func call(verb:String, parameters:[String:AnyObject]) {
        let dict:[String:AnyObject] = [
            "name": verb as AnyObject,
            "hardFail": true as AnyObject,
            "parameters": parameters as AnyObject
        ]
        clientHelper?.publish(composeServiceChannel("call"), message: dict)
    }
    
    
}
