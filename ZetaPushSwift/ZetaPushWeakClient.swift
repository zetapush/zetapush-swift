//
//  ZetaPushWeakClient.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 04/04/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//

import Foundation

open class ZetaPushWeakClient: ClientHelper {
    
    public init(sandboxId: String, weakDeploymentId: String){
        
        let defaults = UserDefaults.standard
        let storedSandboxId = defaults.string(forKey: zetaPushDefaultKeys.sandboxId)
        var stringToken : String = ""
        
        if (storedSandboxId == sandboxId) {
            if let storedToken = defaults.string(forKey: zetaPushDefaultKeys.token) {
                stringToken = storedToken
            }
        }
        
        super.init(apiUrl: "https://api.zpush.io", sandboxId: sandboxId, authentication: Authentication.weak(stringToken, deploymentId: weakDeploymentId), resource: "none", forceHttps: false)
        
        if (storedSandboxId == sandboxId) {
            self.token = stringToken
        }
    }
    
    public convenience init(sandboxId: String) {
        self.init(sandboxId: sandboxId, weakDeploymentId: zetaPushDefaultConfig.weakDeploymentId)
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
    
    
}
