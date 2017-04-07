//
//  ZetaPushService.swift
//  
//
//  Created by Morvan Mikaël on 04/04/2017.
//
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
    
    open func subscribe(verb: String, block:ChannelSubscriptionBlock?=nil)  -> CometdSubscriptionState{
        return (clientHelper?.subscribe(composeServiceChannel(verb), block: block))!
    }
    
    open func unsubscribe(verb: String) {
        clientHelper?.unsubscribe(composeServiceChannel(verb))
    }
    
    open func publish(verb: String, parameters:[String:AnyObject]) {
        clientHelper?.publish(composeServiceChannel(verb), message: parameters)
    }
    
}
