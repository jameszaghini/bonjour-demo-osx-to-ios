//
//  BonjourServer.swift
//  bonjour-demo-mac
//
//  Created by James Zaghini on 14/05/2015.
//  Copyright (c) 2015 James Zaghini. All rights reserved.
//

import Cocoa

enum PacketTag: Int {
    case Header = 1
    case Body = 2
}

protocol BonjourServerDelegate {
    func connected()
    func disconnected()
    func handleBody(body: NSString?)
    func didChangeServices()
}

class BonjourServer: NSObject, NSNetServiceBrowserDelegate, NSNetServiceDelegate, GCDAsyncSocketDelegate {

    var delegate: BonjourServerDelegate!
    
    var coServiceBrowser: NSNetServiceBrowser!
    
    var devices: Array<NSNetService>!
    
    var connectedService: NSNetService!
    
    var sockets: [String : GCDAsyncSocket]!
    
    override init() {
        super.init()
        self.devices = []
        self.sockets = [:]
        self.startService()
    }
    
    func parseHeader(data: NSData) -> UInt {
        var out: UInt = 0
        data.getBytes(&out, length: sizeof(UInt))
        return out
    }
    
    func handleResponseBody(data: NSData) {
        if let message = NSString(data: data, encoding: NSUTF8StringEncoding) {
            self.delegate.handleBody(message)
        }
    }
    
    func connectTo(service: NSNetService) {
        service.delegate = self
        service.resolveWithTimeout(15)
    }
    
    // MARK: NSNetServiceBrowser helpers
    
    func stopBrowsing() {
        if self.coServiceBrowser != nil {
            self.coServiceBrowser.stop()
            self.coServiceBrowser.delegate = nil
            self.coServiceBrowser = nil
        }
    }
    
    func startService() {
        if self.devices != nil {
            self.devices.removeAll(keepCapacity: true)
        }
        
        self.coServiceBrowser = NSNetServiceBrowser()
        self.coServiceBrowser.delegate = self
        self.coServiceBrowser.searchForServicesOfType("_probonjore._tcp.", inDomain: "local.")
    }
    
    func send(data: NSData) {
        print("send data")
        
        if let socket = self.getSelectedSocket() {
            var header = data.length
            let headerData = NSData(bytes: &header, length: sizeof(UInt))
            socket.writeData(headerData, withTimeout: -1.0, tag: PacketTag.Header.rawValue)
            socket.writeData(data, withTimeout: -1.0, tag: PacketTag.Body.rawValue)
        }
    }
    
    func connectToServer(service: NSNetService) -> Bool {
        var connected = false
        
        let addresses: Array = service.addresses!
        var socket = self.sockets[service.name]
        
        if !(socket?.isConnected != nil) {
            socket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
            
            while !connected && Bool(addresses.count) {
                let address: NSData = addresses[0] 
                do {
                    if (try socket?.connectToAddress(address) != nil) {
                        self.sockets.updateValue(socket!, forKey: service.name)
                        self.connectedService = service
                        connected = true
                    }
                } catch {
                    print(error);
                }
            }
        }
        
        return true
    }
    
    // MARK: NSNetService Delegates
    
    func netServiceDidResolveAddress(sender: NSNetService) {
        print("did resolve address \(sender.name)")
        if self.connectToServer(sender) {
            print("connected to \(sender.name)")
        }
    }
    
    func netService(sender: NSNetService, didNotResolve errorDict: [String : NSNumber]) {
        print("net service did no resolve. errorDict: \(errorDict)")
    }   
    
    // MARK: GCDAsyncSocket Delegates
    
    func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        print("connected to host \(host), on port \(port)")
        sock.readDataToLength(UInt(sizeof(UInt64)), withTimeout: -1.0, tag: 0)
    }
    
    func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        print("socket did disconnect \(sock), error: \(err.userInfo)")
    }
    
    func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        print("socket did read data. tag: \(tag)")
        
        if self.getSelectedSocket() == sock {
            
            if data.length == sizeof(UInt) {
                let bodyLength: UInt = self.parseHeader(data)
                sock.readDataToLength(bodyLength, withTimeout: -1, tag: PacketTag.Body.rawValue)
            } else {
                self.handleResponseBody(data)
                sock.readDataToLength(UInt(sizeof(UInt)), withTimeout: -1, tag: PacketTag.Header.rawValue)
            }
        }
    }
    
    func socketDidCloseReadStream(sock: GCDAsyncSocket!) {
        print("socket did close read stream")
    }    
    
    // MARK: NSNetServiceBrowser Delegates
    
    func netServiceBrowser(aNetServiceBrowser: NSNetServiceBrowser, didFindService aNetService: NSNetService, moreComing: Bool) {
        self.devices.append(aNetService)
        if !moreComing {
            self.delegate.didChangeServices()
        }
    }
    
    func netServiceBrowser(aNetServiceBrowser: NSNetServiceBrowser, didRemoveService aNetService: NSNetService, moreComing: Bool) {
        self.devices.removeObject(aNetService)
        if !moreComing {
            self.delegate.didChangeServices()            
        }
    }
    
    func netServiceBrowserDidStopSearch(aNetServiceBrowser: NSNetServiceBrowser) {
        self.stopBrowsing()
    }
    
    func netServiceBrowser(aNetServiceBrowser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        self.stopBrowsing()
    }
    
    // MARK: helpers
    
    func getSelectedSocket() -> GCDAsyncSocket? {
        var sock: GCDAsyncSocket?
        if self.connectedService != nil {
            sock = self.sockets[self.connectedService.name]!
        }
        return sock
    }
    
}
