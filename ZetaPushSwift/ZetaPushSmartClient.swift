//
//  ZetaPushSmartClient.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 04/04/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//

import Foundation
import XCGLogger

/*
  ZetaPush Smart Client
 
  Description: autoconnect with a weak authentication 
   can use credential from simple authentication
   automatic reconnection with stored token
 
*/

open class ZetaPushSmartClient: ClientHelper {
    
    var login: String = ""
    var password: String = ""
    var weakDeploymentId = ""
    var simpleDeploymentId = ""
    var resourceName = ""
    
    public init(sandboxId: String, weakDeploymentId: String, simpleDeploymentId: String, logLevel: XCGLogger.Level = .severe){
        
        self.weakDeploymentId = weakDeploymentId
        self.simpleDeploymentId = simpleDeploymentId
        
        // Get the stored tokens
        let defaults = UserDefaults.standard
        let storedSandboxId = defaults.string(forKey: zetaPushDefaultKeys.sandboxId)
        
        
        var stringToken : String = ""
        var stringPublicToken : String = ""
        if (storedSandboxId == sandboxId) {
            if let storedToken = defaults.string(forKey: zetaPushDefaultKeys.token) {
                stringToken = storedToken
            }
            if let storedPublicToken = defaults.string(forKey: zetaPushDefaultKeys.publicToken) {
                stringPublicToken = storedPublicToken
            }
        }
        if (stringPublicToken.characters.count > 0) {
            // The user is weakly authenticated and the token must be present
            super.init(apiUrl: zetaPushDefaultConfig.apiUrl, sandboxId: sandboxId, authentication: Authentication.weak(stringToken, deploymentId: weakDeploymentId), logLevel: logLevel)
        } else {
            if (stringToken.characters.count > 0){
                // The user is strongly (with a simple authent) authenticated and the token is present
                super.init(apiUrl: zetaPushDefaultConfig.apiUrl, sandboxId: sandboxId, authentication: Authentication.simple(stringToken, password:"", deploymentId: simpleDeploymentId), logLevel: logLevel)
            } else {
                // The use is not authenticated, we connect him with a weak authent
                super.init(apiUrl: zetaPushDefaultConfig.apiUrl, sandboxId: sandboxId, authentication: Authentication.weak("", deploymentId: weakDeploymentId), logLevel: logLevel)
            }
        }
        
        
        
    }
    
    public convenience init(sandboxId: String, logLevel: XCGLogger.Level = .severe){
        self.init(sandboxId: sandboxId, weakDeploymentId: zetaPushDefaultConfig.weakDeploymentId, simpleDeploymentId: zetaPushDefaultConfig.simpleDeploymentId, logLevel: logLevel)
    }
    
    override func storeHandshakeToken(_ authenticationDict: NSDictionary){
        log.debug("storeHandshakeToken")
        let defaults = UserDefaults.standard
        defaults.set(self.getSandboxId(), forKey: zetaPushDefaultKeys.sandboxId)
        if authenticationDict["token"] != nil {
            defaults.set(authenticationDict["token"] as! String, forKey: zetaPushDefaultKeys.token)
        }
        if authenticationDict["publicToken"] != nil {
            defaults.set(authenticationDict["publicToken"] as! String, forKey: zetaPushDefaultKeys.publicToken)
        }
    }
    
    override func eraseHandshakeToken(){
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: zetaPushDefaultKeys.sandboxId)
        defaults.removeObject(forKey: zetaPushDefaultKeys.token)
        defaults.removeObject(forKey: zetaPushDefaultKeys.publicToken)
    }
    
    open func setCredentials(login: String, password: String){
        self.login = login
        self.password = password
        
        let auth = Authentication.simple(login, password: password, deploymentId: self.simpleDeploymentId)
        self.setAuthentication(authentication: auth)
        
        // Delete previously stored tokens
        eraseHandshakeToken()
    }
    
}
