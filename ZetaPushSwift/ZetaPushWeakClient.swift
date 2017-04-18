//
//  ZetaPushWeakClient.swift
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
open class ZetaPushWeakClient: ClientHelper {
    
    public init(sandboxId: String, weakDeploymentId: String, logLevel: XCGLogger.Level = .severe){
        
        let defaults = UserDefaults.standard
        let storedSandboxId = defaults.string(forKey: zetaPushDefaultKeys.sandboxId)
        var stringToken : String = ""
        
        if (storedSandboxId == sandboxId) {
            if let storedToken = defaults.string(forKey: zetaPushDefaultKeys.token) {
                stringToken = storedToken
            }
        }
        
        super.init(apiUrl: zetaPushDefaultConfig.apiUrl, sandboxId: sandboxId, authentication: Authentication.weak(stringToken, deploymentId: weakDeploymentId), logLevel: logLevel)
        
        if (storedSandboxId == sandboxId) {
            self.token = stringToken
        }
    }
    
    public convenience init(sandboxId: String, logLevel: XCGLogger.Level = .severe) {
        self.init(sandboxId: sandboxId, weakDeploymentId: zetaPushDefaultConfig.weakDeploymentId, logLevel: logLevel)
    }
    
    override func storeHandshakeToken(_ authenticationDict: NSDictionary){
        log.debug ("override storeHandshakeToken")
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
    
    
}
