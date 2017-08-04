//
//  ZetaPushServicePublisher.swift
//  ZetaPushSwift
//
//  Created by Mikael Morvan on 20/04/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//

import Foundation
import Gloss

/*
 Class used as a base class for specific ServicePublisher
 
 */
open class ZetaPushServicePublisher{
    
    public var clientHelper: ClientHelper?
    public var zetaPushService: ZetaPushService
    
    public init(_ clientHelper: ClientHelper, deploymentId: String){
        self.clientHelper = clientHelper
        self.zetaPushService = ZetaPushService(clientHelper, deploymentId: deploymentId)
    }
    
}

