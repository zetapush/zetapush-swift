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
    
    public func didDisconnect(_ error: Error?) {
        log.debug("CometdClient didDisconnect")
        self.delegate?.disconnectedFromServer(self)
        self.connectionInitiated = false
        self.cometdConnected = false
    }
    
    public func didFailConnection(_ error: Error?) {
        log.warning("CometdClient didFailConnection")
        self.delegate?.connectionFailed(self)
        self.connectionInitiated = false
        self.cometdConnected = false
    }
    
    public func didWriteError(_ error: Error?) {
        log.error("CometdClient didWriteError " + error.debugDescription)
        self.delegate?.cometdClientError(self, error: error ?? CometdSocketError.transportWrite)
    }
    
    public func didReceiveMessage(_ text: String) {
        log.debug("CometdClient didReceiveMessage " + text)
        self.receive(text)
    }
    
    public func didReceivePong() {
        log.debug("CometdClient didReceivePong")
        self.delegate?.pongReceived(self)
    }
}

