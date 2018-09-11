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
    // Delay in s before automatic reconnection
    var automaticReconnectionDelay:Double = 10
    
    var logLevel: XCGLogger.Level = .severe
    
    fileprivate var authentication: AbstractHandshake?
    let cometdClient: CometdClient
    
    open weak var delegate:ClientHelperDelegate?
    
    let log = XCGLogger(identifier: "zetapushLogger", includeDefaultDestinations: true)
    let tags = XCGLogger.Constants.userInfoKeyTags
    
    public init(apiUrl:String, sandboxId:String, authentication: AbstractHandshake, resource: String = "", logLevel: XCGLogger.Level = .severe ){
        
        self.sandboxId = sandboxId
        self.authentication = authentication
        self.resource = resource
        self.apiUrl = apiUrl
        self.cometdClient = CometdClient()
        super.init()
        
        self.logLevel = logLevel
        log.setup(level: logLevel)
        
        // Handle resource
        let defaults = UserDefaults.standard
        if resource.isEmpty {
            if let storedResource = defaults.string(forKey: zetaPushDefaultKeys.resource) {
                self.resource = storedResource
            } else {
                self.resource = ZetaPushUtils.generateResourceName()
                defaults.set(self.resource, forKey: zetaPushDefaultKeys.resource)
            }
        }
        
        self.cometdClient.delegate = self
    }
    
    open func setAuthentication(authentication: AbstractHandshake){
        self.authentication = authentication
    }
    
    open func setAutomaticReconnectionDelay(delay: Double){
        self.automaticReconnectionDelay = delay
    }
    
    // Disconnect from server
    open func disconnect() {
        log.debug("ClientHelper disconnect", userInfo: [tags: "zetapush"])
        self.wasConnected = false
        self.connected = false
        cometdClient.disconnectFromServer()
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
                
                self.cometdClient.setLogLevel(logLevel: self.logLevel)
                self.cometdClient.configure(url: self.server)
                self.cometdClient.connectHandshake(self.authentication!.getHandshakeFields(self))
            }
            
            task.resume()
 
            
        } else {
            log.debug("ZetaPush configured Server", userInfo: [tags: "zetapush"])
            log.debug(self.server, userInfo: [tags: "zetapush"])
            self.cometdClient.configure(url: self.server)
            self.cometdClient.connectHandshake(self.authentication!.getHandshakeFields(self))
        }
        
    }

    open func subscribe(_ tuples: [ModelBlockTuple]) {
        // Convert model to subscription
        let models: [CometdSubscriptionModel] = tuples.map(cometdClient.modelToSubscription)
            .filter { $0.state.isSubscribingTo }
            .compactMap { $0.state.model }
        // Batch subscriptions
        cometdClient.subscribe(models)
    }
    
    @discardableResult
    open func subscribe(_ channel: String, block: ChannelSubscriptionBlock? = nil) -> Subscription? {
        let (state, sub) = self.cometdClient.subscribeToChannel(channel, block: block)
        guard sub != nil else {
            self.log.error ("sub is NILLLLLL", userInfo: [tags: "zetapush"])
            self.log.error (channel, userInfo: [tags: "zetapush"])
            return nil
        }
        if case let .subscribingTo(model) = state {
            // if channel to subscribe is in state = subscribing to we need to launch the subscription of it
            cometdClient.subscribe(model)
        }
        return sub
    }
    
    open func publish(_ channel:String, message:[String:AnyObject]) {
        self.cometdClient.publish(message, channel: channel)
    }
    
    open func unsubscribe(_ subscription:Subscription){
        log.debug("ClientHelper unsubscribe", userInfo: [tags: "zetapush"])
        self.cometdClient.unsubscribeFromChannel(subscription)
        if let index = self.subscriptionQueue.index(of: subscription){
            self.subscriptionQueue.remove(at: index)
        }
    }
    
    open func logout(){
        log.debug("ClientHelper logout", userInfo: [tags: "zetapush"])
        eraseHandshakeToken()
        disconnect()
    }
    
    open func setForceSecure(_ isSecure: Bool){
        self.cometdClient.setForceSecure(isSecure)
    }
    
    open func composeServiceChannel(_ verb: String, deploymentId: String) -> String {
        return "/service/" + self.sandboxId + "/" + deploymentId + "/" + verb
    }
    
    open func getLogLevel() -> XCGLogger.Level {
        return self.logLevel
    }
    
    open func setLogLevel(logLevel: XCGLogger.Level){
        self.logLevel = logLevel
        log.setup(level: logLevel)
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
        return self.cometdClient.getCometdClientId()
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
        return self.cometdClient.isConnected()
    }
    
    open func getPublicToken() -> String{
        return self.publicToken
    }
    
    open func isWeaklyAuthenticated() -> Bool{
        return !self.publicToken.isEmpty
    }
    
    open func isStronglyAuthenticated() -> Bool{
        return !self.isWeaklyAuthenticated() && !self.token.isEmpty
    }
    
    /*
     Delegate functions from CometdClientDelegate
    */
    
    open func connectedToServer(_ client: CometdClient) {
        log.debug("ClientHelper Connected to ZetaPush server", userInfo: [tags: "zetapush"])
        self.wasConnected = self.connected;
        self.connected = true;
        if (!self.wasConnected && self.connected) {
            _ = self.cometdClient.pendingSubscriptionSchedule.isValid
            self.delegate?.onConnectionEstablished(self);
        }
    }
    
    
    open func handshakeSucceeded(_ client:CometdClient, handshakeDict: NSDictionary){
        log.debug("ClientHelper Handshake Succeeded", userInfo: [tags: "zetapush"])
        log.debug(handshakeDict, userInfo: [tags: "zetapush"])
        let authentication : NSDictionary = handshakeDict["authentication"] as! NSDictionary
        
        if authentication["token"] != nil {
           self.token = authentication["token"] as! String
        }
        
        if authentication["publicToken"] != nil {
            self.publicToken = authentication["publicToken"] as! String
        }
        
        self.userId = authentication["userId"] as! String
        storeHandshakeToken(authentication)
        
        self.subsbribeQueuedSubscriptions();
        
        self.delegate?.onSuccessfulHandshake(self)
    }

    func subsbribeQueuedSubscriptions() {
        log.debug("ClientHelper subscribe queued subscriptions", userInfo: [tags: "zetapush"])
        // Automatic resubscribe after handshake (not the first one)
        if !firstHandshakeFlag {
            
            var tempArray = Array<Subscription>()
            for sub in self.subscriptionQueue {
                tempArray.append(sub)
            }
            self.subscriptionQueue.removeAll()
            for sub in tempArray {
                self.subscribe(sub.channel, block: sub.callback)
            }
        }
        firstHandshakeFlag = false
    }
    
    open func handshakeFailed(_ client: CometdClient){
        log.error("ClientHelper Handshake Failed", userInfo: [tags: "zetapush"])
        self.delegate?.onFailedHandshake(self)
    }
    
    open func connectionFailed(_ client: CometdClient) {
        log.error("ClientHelper Failed to connect to Cometd server!", userInfo: [tags: "zetapush"])
        if self.wasConnected {
            Timer.scheduledTimer(timeInterval: self.automaticReconnectionDelay,
                                 target: self,
                                 selector: #selector(self.connectionFailedTimer),
                                 userInfo: nil,
                                 repeats: false)
        }
        self.delegate?.onConnectionBroken(self)
    }
    
    @objc
    func connectionFailedTimer(timer: Timer){
        log.debug("ClientHelper connection failed timer", userInfo: [tags: "zetapush"])
        self.connect()
    }
    
    open func disconnectedFromServer(_ client: CometdClient) {
        log.debug("ClientHelper Disconnected from Cometd server", userInfo: [tags: "zetapush"])
        self.connected = false;
        self.delegate?.onConnectionClosed(self)
    }
    
    open func disconnectedAdviceReconnect(_ client:CometdClient){
        log.debug("ClientHelper Disconnected from Cometd server", userInfo: [tags: "zetapush"])
        self.delegate?.onConnectionClosedAdviceReconnect(self)
    }
    
    open func didSubscribeToChannel(_ client: CometdClient, channel: String) {
        log.debug("ClientHelper Subscribed to channel \(channel)", userInfo: [tags: "zetapush"])
        self.delegate?.onDidSubscribeToChannel(self, channel: channel)
    }
    
    open func didUnsubscribeFromChannel(_ client: CometdClient, channel: String) {
        log.debug("ClientHelper Unsubscribed from channel \(channel)", userInfo: [tags: "zetapush"])
        self.delegate?.onDidUnsubscribeFromChannel(self, channel: channel)
    }
    
    open func subscriptionFailedWithError(_ client: CometdClient, error:subscriptionError) {
        log.error("ClientHelper Subscription failed", userInfo: [tags: "zetapush"])
        self.delegate?.onSubscriptionFailedWithError(self, error: error)
    }
    
    open func messageReceived(_ client: CometdClient, messageDict: NSDictionary, channel: String) {
        log.debug("ClientHelper messageReceived \(channel)", userInfo: [tags: "zetapush"])
        log.debug(messageDict, userInfo: [tags: "zetapush"])
    }
    
}


