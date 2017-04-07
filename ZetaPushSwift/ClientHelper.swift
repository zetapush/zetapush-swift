//
//  ZetaPushClient+Helper.swift
//  Pods
//
//  Created by Morvan Mikaël on 28/03/2017.
//
//

import Foundation

/*
    Base class for managing ZetaPush connexion
*/

open class ClientHelper : NSObject, CometdClientDelegate{
    
    var sandboxId:String = ""
    var server:String = ""
    var apiUrl:String = ""
    var connected:Bool = false
    var userId:String = ""
    var resource:String = ""
    var token:String = ""
    var publicToken:String = ""
    
    var subscriptionQueue = Array<Subscription>()
    
    fileprivate var wasConnected:Bool = false
    fileprivate var authentication: AbstractHandshake?
    var cometdClient: CometdClient?
    
    // Callbacks for connection
    open var onConnectionEstablished : ((_ client:ClientHelper)->())?
    open var onConnectionBroken : ((_ client:ClientHelper)->())?
    open var onConnectionClosed : ((_ client:ClientHelper)->())?
    open var onSuccessfulHandshake : ((_ client:ClientHelper)->())?
    open var onFailedHandshake : ((_ client:ClientHelper)->())?
    
    
    // Callbacks for Subscription
    open var onDidSubscribeToChannel : ((_ client:ClientHelper, _ channel:String)->())?
    open var onDidUnsubscribeToChannel : ((_ client:ClientHelper, _ channel:String)->())?
    open var onSubscriptionFailedWithError : ((_ client:ClientHelper, _ error:subscriptionError)->())?
    
    open var onMessageReceived : ((_ client:ClientHelper, _ messageDict : NSDictionary, _ channel:String)->())?
    
    public init(apiUrl:String, sandboxId:String, authentication: AbstractHandshake, resource: String, forceHttps:Bool? ){
        
        self.sandboxId = sandboxId
        self.authentication = authentication
        self.resource = resource
        self.apiUrl = apiUrl
        self.cometdClient = CometdClient()
        super.init()
        
        self.cometdClient?.delegate = self
    }
    
    
    open func setAuthentication(authentication: AbstractHandshake){
        self.authentication = authentication
    }
    
    // Disconnect from server
    open func disconnect(){
        cometdClient!.disconnectFromServer()
    }
    
    // Connect to server
    open func connect(){
        
        self.server = "ws://vm-str-2:8080/str/strd"
        //self.server = "ws://localhost:5222/faye"
        
        if self.server == "" {
            // Check the http://api.zpush.io with sandboxId

            let url = URL(string: self.apiUrl + sandboxId)
            
            let task = URLSession.shared.dataTask(with: url!) { data, response, error in
                
                guard error == nil else {
                    print (error!)
                    return
                }
                
                guard data != nil else {
                    print ("No server for the sandbox")
                    return
                }
                
                let json = try! JSONSerialization.jsonObject(with: data!, options: [])
                print (json)
            }
            
            task.resume()
            
        }
        
        self.cometdClient?.configure(url: self.server)
        self.cometdClient?.connectHandshake(self.authentication!.getHandshakeFields(self))
    }
    
    open func subscribe(_ channel:String, block:ChannelSubscriptionBlock?=nil) -> Subscription {
        let (cometdSubscriptionState, sub) = self.cometdClient!.subscribeToChannel(channel, block: block)
        print ("subscribe ", cometdSubscriptionState)
        switch cometdSubscriptionState {
        case .subscribingTo:
            print ("subscribe subscribingTo")
            self.subscriptionQueue.append(sub!)
        default:
            print ("subscribe default")
        }
        /*
        if cometdSubscriptionState == CometdSubscriptionState.subscribed(nil) {
            print ("subscribe subscribed")
        }
        if let sub = sub {
            self.subscriptionQueue.append(sub)
        }
        */
        return sub!
    }
    
    open func publish(_ channel:String, message:[String:AnyObject]) {
        self.cometdClient!.publish(message, channel: channel)
    }
    
    open func unsubscribe(_ subscription:Subscription){
        self.cometdClient!.unsubscribeFromChannel(subscription)
        if let index = self.subscriptionQueue.index(of: subscription){
            self.subscriptionQueue.remove(at: index)
        }
    }
    
    open func logout(){
        eraseHandshakeToken()
        disconnect()
    }
    
    /*
     Must be overriden by ClientHelper descendants
     */
    func storeHandshakeToken(_ authenticationDict: NSDictionary){}
    /*
     Must be overriden by ClientHelper descendants
     */
    func eraseHandshakeToken(){}
    
    open func getClientId() -> String{
        return self.cometdClient!.getCometdClientId()
    }
    
    open func getHandshakeFields() -> [String: AnyObject]{
        return self.authentication!.getHandshakeFields(self)
    }
    
    open func getResource() -> String{
        return self.resource
    }
    
    open func getSandboxId() -> String{
        return self.sandboxId
    }
    
    open func getServers(){
        //return self.servers
    }
    
    open func getUserId() -> String{
        return self.userId
    }
    
    open func isConnected() -> Bool{
        return self.cometdClient?.isConnected() ?? false
    }
    
    open func getPublicToken() -> String{
        return self.publicToken
    }
    
    open func isWeaklyAuthenticated() -> Bool{
        return self.publicToken.characters.count > 0
    }
    
    open func isStronglyAuthenticated() -> Bool{
        return !self.isWeaklyAuthenticated() && self.token.characters.count > 0
    }
    
    /*
     Delegate functions from CometdClientDelegate
    */
    
    open func connectedToServer(_ client: CometdClient) {
        print("ClientHelper Connected to ZetaPush server")
        onConnectionEstablished?(self)
        onSuccessfulHandshake?(self)
    }
    
    
    open func handshakeSucceeded(_ client:CometdClient, handshakeDict: NSDictionary){
        print("ClientHelper Handshake Succeeded", handshakeDict)
        let authentication : NSDictionary = handshakeDict["authentication"] as! NSDictionary
        
        if authentication["token"] != nil {
           self.token = authentication["token"] as! String
        }
        
        self.userId = authentication["userId"] as! String
        storeHandshakeToken(authentication)
        
        // Automatic resubscribe after handshake
        var tempArray = Array<Subscription>()
        for sub in self.subscriptionQueue {
            tempArray.append(sub)
        }
        self.subscriptionQueue.removeAll()
        for sub in tempArray {
            _ = self.subscribe(sub.channel, block: sub.callback)
        }
    }
    
    open func handshakeFailed(_ client: CometdClient){
        print("ClientHelper Handshake Failed")
        onFailedHandshake?(self)
    }
    
    open func connectionFailed(_ client: CometdClient) {
        print("ClientHelper Failed to connect to Cometd server!")
        onConnectionBroken?(self)
    }
    
    open func disconnectedFromServer(_ client: CometdClient) {
        print("ClientHelper Disconnected from Cometd server")
        onConnectionClosed?(self)
    }
    
    open func didSubscribeToChannel(_ client: CometdClient, channel: String) {
        print("ClientHelper Subscribed to channel \(channel)")
        onDidSubscribeToChannel?(self, channel)
    }
    
    open func didUnsubscribeFromChannel(_ client: CometdClient, channel: String) {
        print("ClientHelper Unsubscribed from channel \(channel)")
        onDidUnsubscribeToChannel?(self, channel)
    }
    
    open func subscriptionFailedWithError(_ client: CometdClient, error:subscriptionError) {
        print("ClientHelper Subscription failed")
        onSubscriptionFailedWithError?(self, error)
    }
    
    open func messageReceived(_ client: CometdClient, messageDict: NSDictionary, channel: String) {
        print("ClientHelper messageReceived", channel, messageDict)
        onMessageReceived?(self, messageDict, channel)
        
    }
    
}


