//
//  WebsocketTransport.swift
//  ZetaPushSwift
//
//  Created by Morvan Mikaël on 23/03/2017.
//  Copyright © 2017 ZetaPush. All rights reserved.
//
// Adapted from https://github.com/hamin/FayeSwift

import Foundation
import SwiftWebSocket
import XCGLogger

internal class WebsocketTransport: Transport {
    var urlString:String?
    var webSocket:WebSocket?
    internal var delegate:TransportDelegate!
    
    let log = XCGLogger(identifier: "websocketLogger", includeDefaultDestinations: true)
    
    convenience required internal init(url: String, logLevel: XCGLogger.Level = .severe) {
        self.init()
        self.urlString = url
        log.setup(level: logLevel)
    }
    
    func openConnection() {
        self.closeConnection()
        self.webSocket = WebSocket(url: URL(string:self.urlString!)!)
        if let webSocket = self.webSocket {
            log.debug("Cometd: open connection")
            webSocket.event.open = {
                self.delegate.didConnect()
            }
            webSocket.event.close = { _, _, _ in
                self.delegate.didDisconnect(CometdSocketError.lostConnection)
            }
            webSocket.event.error = { error in
                self.log.debug("Cometd: Received error : \(error)")
                self.delegate.didFailConnection(error)
            }
            webSocket.event.message = { message in
                guard let text = message as? String else {
                    return
                }
                self.log.debug("Cometd: Received message : \(text)")
                self.delegate?.didReceiveMessage(text)
            }
            webSocket.open()
            log.debug("Cometd: Opening connection with \(String(describing: self.urlString))")
        }
    }
    
    func closeConnection() {
        log.debug("Cometd: close connection | ws is connected -> \(isConnected)")
        guard isConnected else {
            return
        }
        self.webSocket?.close()
    }
    
    var isConnected: Bool {
        let state = self.webSocket?.readyState ?? .closed
        return state == .open
    }
    
    func writeString(_ aString:String) {
        log.debug("Cometd: write string. socket -> \(isConnected)")
        self.webSocket?.send(aString)
    }
}

