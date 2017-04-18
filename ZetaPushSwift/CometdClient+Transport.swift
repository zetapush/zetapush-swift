//
//  CometdClient+Transport.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 23/03/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift


import Foundation

// MARK: Transport Delegate
extension CometdClient {
    public func didConnect() {
        self.connectionInitiated = false;
        log.debug("CometdClient didConnect")
        self.handshake(self.handshakeFields!)
    }
    
    public func didDisconnect(_ error: NSError?) {
        log.debug("CometdClient didDisconnect")
        self.delegate?.disconnectedFromServer(self)
        self.connectionInitiated = false
        self.cometdConnected = false
    }
    
    public func didFailConnection(_ error: NSError?) {
        log.warning("CometdClient didFailConnection")
        self.delegate?.connectionFailed(self)
        self.connectionInitiated = false
        self.cometdConnected = false
    }
    
    public func didWriteError(_ error: NSError?) {
        self.delegate?.cometdClientError(self, error: error ?? NSError(error: .transportWrite))
    }
    
    public func didReceiveMessage(_ text: String) {
        self.receive(text)
    }
    
    public func didReceivePong() {
        self.delegate?.pongReceived(self)
    }
}

