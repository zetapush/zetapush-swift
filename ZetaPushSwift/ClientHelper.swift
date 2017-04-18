//
//  ZetaPushClient+Helper.swift
//  Pods
//
//  Created by Morvan Mikaël on 28/03/2017.
//
//

import Foundation
import XCGLogger

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
    
    var firstHandshakeFlag:Bool = true
    
    var subscriptionQueue = Array<Subscription>()
    // Flag used for automatic reconnection
    var wasConnected:Bool = false
    
    
    fileprivate var authentication: AbstractHandshake?
    var cometdClient: CometdClient?
    
    // Callbacks for connection
    open var onConnectionEstablished : ((_ client:ClientHelper)->())?
    open var onConnectionBroken : ((_ client:ClientHelper)->())?
    open var onConnectionClosed : ((_ client:ClientHelper)->())?
    open var onSuccessfulHandshake : ((_ client:ClientHelper)->())?
    open var onFailedHandshake : ((_ client:ClientHelper)->())?
    
    
    let log = XCGLogger(identifier: "zetapushLogger", includeDefaultDestinations: true)
    let tags = XCGLogger.Constants.userInfoKeyTags
    
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
        
        // Handle resource
        let defaults = UserDefaults.standard
        if resource.characters.count == 0 {
            if let storedResource = defaults.string(forKey: zetaPushDefaultKeys.resource) {
                self.resource = storedResource
            } else {
                self.resource = ZetaPushUtils.generateResourceName()
                defaults.set(self.resource, forKey: zetaPushDefaultKeys.resource)
            }
        }
        
        self.cometdClient?.delegate = self
    }
    
    open func setAuthentication(authentication: AbstractHandshake){
        self.authentication = authentication
    }
    
    // Disconnect from server
    open func disconnect(){
        self.wasConnected = false;
        cometdClient!.disconnectFromServer()
    }
    
    // Connect to server
    open func connect(){

        if self.server == "" {
            // Check the http://api.zpush.io with sandboxId
            
            let url = URL(string: self.apiUrl + "/" + sandboxId)
            
            let task = URLSession.shared.dataTask(with: url!) { data, response, error in
                
                guard error == nil else {
                    self.log.error (error!)
                    return
                }
                
                guard data != nil else {
                    self.log.error ("No server for the sandbox", userInfo: [self.tags: "zetapush"])
                    return
                }
                
                let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String:AnyObject]
                let servers = json["servers"] as! [AnyObject]
                let randomIndex = Int(arc4random_uniform(UInt32(servers.count)))
                self.server = servers[randomIndex] as! String + "/strd"
                self.log.debug("ZetaPush selected Server")
                self.log.debug(self.server)
                
                self.cometdClient?.configure(url: self.server)
                self.cometdClient?.connectHandshake(self.authentication!.getHandshakeFields(self))
            }
            
            task.resume()
 
            
        } else {
            log.debug("ZetaPush configured Server", userInfo: [tags: "zetapush"])
            log.debug(self.server, userInfo: [tags: "zetapush"])
            self.cometdClient?.configure(url: self.server)
            self.cometdClient?.connectHandshake(self.authentication!.getHandshakeFields(self))
        }
        
    }
    
    open func subscribe(_ channel:String, block:ChannelSubscriptionBlock?=nil) -> Subscription {
        let (_, sub) = self.cometdClient!.subscribeToChannel(channel, block: block)
        
        if let sub = sub {
            self.subscriptionQueue.append(sub)
        } else {
            self.log.error ("sub is NILLLLLL", userInfo: [tags: "zetapush"])
            self.log.error (channel, userInfo: [tags: "zetapush"])
        }
        
        return sub!
    }
    
    open func publish(_ channel:String, message:[String:AnyObject]) {
        self.cometdClient!.publish(message, channel: channel)
    }
    
    open func unsubscribe(_ subscription:Subscription){
        log.debug("ClientHelper unsubscribe", userInfo: [tags: "zetapush"])
        self.cometdClient!.unsubscribeFromChannel(subscription)
        if let index = self.subscriptionQueue.index(of: subscription){
            self.subscriptionQueue.remove(at: index)
        }
    }
    
    open func logout(){
        eraseHandshakeToken()
        disconnect()
    }
    
    open func setForceSecure(_ isSecure: Bool){
        self.cometdClient!.setForceSecure(isSecure)
    }
    
    open func composeServiceChannel(_ verb: String, deploymentId: String) -> String {
        return "/service/" + self.sandboxId + "/" + deploymentId + "/" + verb
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
    
    open func getServer() -> String{
        return self.server
    }
    
    open func setServerUrl(_ serverUrl: String){
        self.server = serverUrl
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
        log.debug("ClientHelper Connected to ZetaPush server", userInfo: [tags: "zetapush"])
        onConnectionEstablished?(self)
        onSuccessfulHandshake?(self)
    }
    
    
    open func handshakeSucceeded(_ client:CometdClient, handshakeDict: NSDictionary){
        log.debug("ClientHelper Handshake Succeeded", userInfo: [tags: "zetapush"])
        log.debug(handshakeDict, userInfo: [tags: "zetapush"])
        let authentication : NSDictionary = handshakeDict["authentication"] as! NSDictionary
        
        if authentication["token"] != nil {
           self.token = authentication["token"] as! String
        }
        
        self.userId = authentication["userId"] as! String
        storeHandshakeToken(authentication)
        
        self.wasConnected = true
        
        // Automatic resubscribe after handshake (not the first one)
        if !firstHandshakeFlag {
            
            var tempArray = Array<Subscription>()
            for sub in self.subscriptionQueue {
                tempArray.append(sub)
            }
            self.subscriptionQueue.removeAll()
            for sub in tempArray {
                _ = self.subscribe(sub.channel, block: sub.callback)
            }
        }
        
        firstHandshakeFlag = false
 
    }
    
    open func handshakeFailed(_ client: CometdClient){
        log.error("ClientHelper Handshake Failed", userInfo: [tags: "zetapush"])
        onFailedHandshake?(self)
    }
    
    open func connectionFailed(_ client: CometdClient) {
        log.error("ClientHelper Failed to connect to Cometd server!", userInfo: [tags: "zetapush"])
        if self.wasConnected {
            Timer.scheduledTimer(timeInterval: 10,
                                 target: self,
                                 selector: #selector(self.connectionFailedTimer),
                                 userInfo: nil,
                                 repeats: false)
        }
        onConnectionBroken?(self)
    }
    
    func connectionFailedTimer(timer: Timer){
        self.connect()
    }
    
    open func disconnectedFromServer(_ client: CometdClient) {
        log.debug("ClientHelper Disconnected from Cometd server", userInfo: [tags: "zetapush"])
        onConnectionClosed?(self)
    }
    
    open func didSubscribeToChannel(_ client: CometdClient, channel: String) {
        log.debug("ClientHelper Subscribed to channel \(channel)", userInfo: [tags: "zetapush"])
        onDidSubscribeToChannel?(self, channel)
    }
    
    open func didUnsubscribeFromChannel(_ client: CometdClient, channel: String) {
        log.debug("ClientHelper Unsubscribed from channel \(channel)", userInfo: [tags: "zetapush"])
        onDidUnsubscribeToChannel?(self, channel)
    }
    
    open func subscriptionFailedWithError(_ client: CometdClient, error:subscriptionError) {
        log.error("ClientHelper Subscription failed", userInfo: [tags: "zetapush"])
        onSubscriptionFailedWithError?(self, error)
    }
    
    open func messageReceived(_ client: CometdClient, messageDict: NSDictionary, channel: String) {
        log.debug("ClientHelper messageReceived \(channel)", userInfo: [tags: "zetapush"])
        log.debug(messageDict, userInfo: [tags: "zetapush"])
        onMessageReceived?(self, messageDict, channel)
        
    }
    
}


