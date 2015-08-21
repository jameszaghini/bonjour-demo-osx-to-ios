//
//  BonjourController.swift
//  bonjour-demo-ios
//
//  Created by James Zaghini on 12/05/2015.
//  Copyright (c) 2015 James Zaghini. All rights reserved.
//

import UIKit

enum PacketTag: Int {
    case Header = 1
    case Body = 2
}

protocol BonjourClientDelegate {
    func connectedTo(socket: GCDAsyncSocket!)
    func disconnected()
    func handleBody(body: NSString?)
}

class BonjourClient: NSObject, NSNetServiceDelegate, NSNetServiceBrowserDelegate, GCDAsyncSocketDelegate {
   
    var delegate: BonjourClientDelegate!
    
    var service: NSNetService!
    
    var socket: GCDAsyncSocket!
    
    override init() {
        super.init()
        self.startBroadCasting()
    }
    
    func startBroadCasting() {
        self.socket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        var error: NSError?
        do {
            try self.socket.acceptOnPort(0)
            self.service = NSNetService(domain: "local.", type: "_probonjore._tcp.", name: UIDevice.currentDevice().name, port: Int32(self.socket.localPort))
            self.service.delegate = self
            self.service.publish()
        } catch let error1 as NSError {
            error = error1
            print("Unable to create socket. Error \(error)")
        }
    }
    
    func parseHeader(data: NSData) -> UInt {
        var out: UInt = 0
        data.getBytes(&out, length: sizeof(UInt))
        return out
    }
    
    func handleResponseBody(data: NSData) -> NSString? {
        if let message = NSString(data: data, encoding: NSUTF8StringEncoding) {
            return message
        }
        return nil
    }
    
    func send(data: NSData) {
        var header = data.length
        let headerData = NSData(bytes: &header, length: sizeof(UInt))
        self.socket.writeData(headerData, withTimeout: -1.0, tag: PacketTag.Header.rawValue)
        self.socket.writeData(data, withTimeout: -1.0, tag: PacketTag.Body.rawValue)
    }
    
    /// MARK: NSNetService Delegates
    
    func netServiceDidPublish(sender: NSNetService) {
        print("Bonjour service published. domain: \(sender.domain), type: \(sender.type), name: \(sender.name), port: \(sender.port)")
    }
    
    func netService(sender: NSNetService, didNotPublish errorDict: [String : NSNumber]) {
        print("Unable to create socket. domain: \(sender.domain), type: \(sender.type), name: \(sender.name), port: \(sender.port), Error \(errorDict)")
    }
    
    /// MARK: GCDAsyncSocket Delegates
    
    func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        print("Did accept new socket")
        self.socket = newSocket
        self.socket.readDataToLength(UInt(sizeof(UInt64)), withTimeout: -1.0, tag: 0)
        self.delegate.connectedTo(newSocket)
    }
    
    func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        print("socket did disconnect: error \(err)")
        if self.socket == socket {
            self.delegate.disconnected()
        }
    }
    
    func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        print("did read data")
        
        if data.length == sizeof(UInt) {
            let bodyLength: UInt = self.parseHeader(data)
            sock.readDataToLength(bodyLength, withTimeout: -1, tag: PacketTag.Body.rawValue)
        } else {
            let body = self.handleResponseBody(data)
            self.delegate.handleBody(body)
            sock.readDataToLength(UInt(sizeof(UInt)), withTimeout: -1, tag: PacketTag.Header.rawValue)
        }
    }
    
    func socket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
        print("did write data with tag: \(tag)")
    }
}
