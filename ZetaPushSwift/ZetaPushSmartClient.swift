//
//  ZetaPushSmartClient.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 04/04/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//

import Foundation

open class ZetaPushSmartClient: ClientHelper {
    
    var login: String = ""
    var password: String = ""
    var weakDeploymentId = ""
    var simpleDeploymentId = ""
    
    public init(sandboxId: String, weakDeploymentId: String, simpleDeploymentId: String){
        
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
            super.init(apiUrl: "https://api.zpush.io", sandboxId: sandboxId, authentication: Authentication.weak(stringToken, deploymentId: weakDeploymentId), resource: "none", forceHttps: false)
        } else {
            if (stringToken.characters.count > 0){
                // The user is strongly (with a simple authent) authenticated and the token is present
                super.init(apiUrl: "https://api.zpush.io", sandboxId: sandboxId, authentication: Authentication.simple(stringToken, password:"", deploymentId: simpleDeploymentId), resource: "none", forceHttps: false)
            } else {
                // The use is not authenticated, we connect him with a weak authent
                super.init(apiUrl: "https://api.zpush.io", sandboxId: sandboxId, authentication: Authentication.weak("", deploymentId: weakDeploymentId), resource: "none", forceHttps: false)
            }
        }
        
        
        
    }
    
    public convenience init(sandboxId: String){
        self.init(sandboxId: sandboxId, weakDeploymentId: zetaPushDefaultConfig.weakDeploymentId, simpleDeploymentId: zetaPushDefaultConfig.simpleDeploymentId)
    }
    
    override func storeHandshakeToken(_ authenticationDict: NSDictionary){
        print ("override storeHandshakeToken")
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
