//
//  ZetaPushService.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 04/04/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//

import Foundation

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
        
        clientHelper?.publish(composeServiceChannel("verb"), message: parameters)
    }
    
}
