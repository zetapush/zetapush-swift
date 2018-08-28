//
//  CometdSubscriptionModel.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 23/03/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

import Foundation
import SwiftyJSON

public enum CometdSubscriptionModelError: Error {
    case conversationError
    case clientIdNotValid
}

// MARK:
// MARK: CometdSubscriptionModel

///  Subscription Model
open class CometdSubscriptionModel {
    static var id: Int = 0;
    /// Subscription URL
    open let subscriptionUrl: String
    
    /// Channel type for request
    open let bayeuxChannel: BayeuxChannel
    
    /// Uniqle client id for socket
    open var clientId: String?
    
    // Id of the subscribtion
    open var id: Int?
    
    /// Model must conform to Hashable
    open var hashValue: Int {
        return subscriptionUrl.hashValue
    }
    
    // MARK:
    // MARK: Init
    
    public init(subscriptionUrl: String, bayeuxChannel: BayeuxChannel=BayeuxChannel.Subscribe, clientId: String?) {
        self.subscriptionUrl = subscriptionUrl
        self.bayeuxChannel = bayeuxChannel
        self.clientId = clientId
        CometdSubscriptionModel.id += 1
        self.id = CometdSubscriptionModel.id
    }
    
    // MARK:
    // MARK: JSON
    
    ///  Return Json string from model
    open func jsonString() throws -> String {
        do {
            guard let model = try JSON(toDictionary()).rawString() else {
                throw CometdSubscriptionModelError.conversationError
            }
            
            return model
        } catch {
            throw CometdSubscriptionModelError.clientIdNotValid
        }
    }
    
    // MARK:
    // MARK: Helper
    
    ///  Create dictionary of model object, Subclasses should override method to return custom model
    open func toDictionary() throws -> [String: AnyObject] {
        guard let clientId = clientId else {
            throw CometdSubscriptionModelError.clientIdNotValid
        }
        
        return [Bayeux.Channel.rawValue: bayeuxChannel.rawValue as AnyObject,
                Bayeux.ClientId.rawValue: clientId as AnyObject,
                Bayeux.Id.rawValue: id as AnyObject,
                Bayeux.Subscription.rawValue: subscriptionUrl as AnyObject]
    }
}

// MARK:
// MARK: Description

extension CometdSubscriptionModel: CustomStringConvertible {
    
    public var description: String {
        return "CometdSubscriptionModel: \(String(describing: try? self.toDictionary()))"
    }
}

// MARK:
// MARK: Equatable

public func ==(lhs: CometdSubscriptionModel, rhs: CometdSubscriptionModel) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

