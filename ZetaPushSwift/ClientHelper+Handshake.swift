//
//  ZetaPushClient+Handshake.swift
//  Pods
//
//  Created by Morvan Mikaël on 28/03/2017.
//
//

/*
 
    Handle Simple, Weak and Delegating authentication for ZetaPush
 
 */
import Foundation

enum AuthentType : String {
    case Auth_File = "file";
    case Auth_Simple = "simple";
    case Auth_Weak = "weak";
    case Auth_Delegating = "delegating";
}

open class AbstractHandshake {
    
    var deploymentId:String = ""
    var authType:String = ""
    
    public init (authType: String, deploymentId: String){
        self.authType = authType
        self.deploymentId = deploymentId
    }
    
    func getHandshakeFields(_ client : ClientHelper) -> [String: AnyObject] {
        var auth = [String: AnyObject]()
        auth["type"] =  client.getSandboxId() + "." + deploymentId + "." + getAuthType() as AnyObject?
        auth["version"] = getAuthVersion() as AnyObject?
        auth["data"] = getAuthData() as AnyObject?
        auth["resource"] = client.getResource() as AnyObject?
        return auth
    }
    
    func getAuthType() -> String {
        return authType
    }
    
    func getAuthVersion() -> String {
        return "none"
    }
    
    func getAuthData() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["error"] = "method must be overridden" as AnyObject?
        return dict
    }
}

open class TokenHandshake : AbstractHandshake {
    
    fileprivate var token: String = ""
    
    public init(token: String, deploymentId: String, authType: String) {
        super.init(authType: authType, deploymentId: deploymentId)
        self.token = token
    }
    
    override func getAuthData() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["token"] = self.token as AnyObject?
        return dict
    }
}

open class CredentialsHanshake : AbstractHandshake {
    fileprivate var login: String = ""
    fileprivate var password : String = ""
    
    public init(login: String, password: String, deploymentId: String, authType: String) {
        super.init(authType: authType, deploymentId: deploymentId)
        self.login = login
        self.password = password
    }
    
    override func getAuthData() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["login"] = self.login as AnyObject?
        dict["password"] = self.password as AnyObject?
        return dict
    }
}

open class Authentication {
    
    open static func createHandshake(_ login: String, password: String, deploymentId: String, authType: String) -> AbstractHandshake {
        if password.characters.count == 0 {
            return TokenHandshake(token: login, deploymentId: deploymentId, authType: authType)
        } else {
            return CredentialsHanshake(login: login, password: password, deploymentId: deploymentId, authType: authType)
        }
    }
    
    open static func simple(_ login: String, password: String, deploymentId: String) -> AbstractHandshake {
        return createHandshake(login, password: password, deploymentId: deploymentId, authType: AuthentType.Auth_Simple.rawValue)
    }
    
    open static func weak(_ token: String, deploymentId: String) -> AbstractHandshake {
        return createHandshake(token, password: "", deploymentId: deploymentId, authType: AuthentType.Auth_Weak.rawValue)
    }
    
    open static func delegating(_ token: String, deploymentId: String) ->AbstractHandshake {
        return createHandshake(token, password: "", deploymentId: deploymentId, authType: AuthentType.Auth_Delegating.rawValue)
    }
    
}



