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
    var isConnected: Bool { get }
}

public protocol TransportDelegate: class {
    func didConnect()
    func didFailConnection(_ error: Error?)
    func didDisconnect(_ error: Error?)
    func didWriteError(_ error: Error?)
    func didReceiveMessage(_ text:String)
    func didReceivePong()
}
