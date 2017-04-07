//
//  Transport.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 23/03/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

public protocol Transport {
    func writeString(_ aString:String)
    func openConnection()
    func closeConnection()
    func isConnected() -> (Bool)
}

public protocol TransportDelegate: class {
    func didConnect()
    func didFailConnection(_ error:NSError?)
    func didDisconnect(_ error: NSError?)
    func didWriteError(_ error:NSError?)
    func didReceiveMessage(_ text:String)
    func didReceivePong()
}
