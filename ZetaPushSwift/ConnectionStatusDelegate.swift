//
//  ZetaPushClientDelegate.swift
//  Pods
//
//  Created by Morvan Mikaël on 28/03/2017.
//
//
// Adapted from https://github.com/hamin/FayeSwift

import Foundation

public protocol ConnectionStatusDelegate: NSObjectProtocol {
    func onConnectionEstablished(_ client:ClientHelper)
    func onConnectionBroken(_ client:ClientHelper)
    func onConnectionClosed(_ client:ClientHelper)
    func onSuccessfulHandshake(_ client:ClientHelper)
    func onFailedHandshake(_ client:ClientHelper)
}

public extension ConnectionStatusDelegate {
    func onConnectionEstablished(_ client:ClientHelper){}
    func onConnectionBroken(_ client:ClientHelper){}
    func onConnectionClosed(_ client:ClientHelper){}
    func onSuccessfulHandshake(_ client:ClientHelper){}
    func onFailedHandshake(_ client:ClientHelper){}
}
