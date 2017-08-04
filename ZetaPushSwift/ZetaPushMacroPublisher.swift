//
//  ZetaPushMacroPublisher.swift
//  ZetaPushSwift
//
//  Created by Mikael Morvan on 20/04/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//

import Foundation
import Gloss

/*
    Class used as a base class for specific MacroPublisher
 
 */
open class ZetaPushMacroPublisher{
    
    public var clientHelper: ClientHelper?
    public var zetaPushMacroService: ZetaPushMacroService
    
    public init(_ clientHelper: ClientHelper, deploymentId: String){
        self.clientHelper = clientHelper
        self.zetaPushMacroService = ZetaPushMacroService(clientHelper, deploymentId: deploymentId)
    }
    
    public convenience init(_ clientHelper: ClientHelper){
        self.init(clientHelper, deploymentId: zetaPushDefaultConfig.macroDeployementId)
    }

}

