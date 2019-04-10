//
//  BonjourServer.swift
//  bonjour-demo-mac
//
//  Created by James Zaghini on 14/05/2015.
//  Copyright (c) 2015 James Zaghini. All rights reserved.
//

import Cocoa

enum PacketTag: Int {
    case header = 1
    case body = 2
}

protocol BonjourServerDelegate {
    func connected()
    func disconnected()
    func handleBody(_ body: NSString?)
    func didChangeServices()
}

class BonjourServer: NSObject, NetServiceBrowserDelegate, NetServiceDelegate, GCDAsyncSocketDelegate {

    var delegate: BonjourServerDelegate!
    
    var coServiceBrowser: NetServiceBrowser!
    
    var devices: Array<NetService>!
    
    var connectedService: NetService!
    
    var sockets: [String : GCDAsyncSocket]!
    
    override init() {
        super.init()
        self.devices = []
        self.sockets = [:]
        self.startService()
    }
    
    func parseHeader(_ data: Data) -> UInt {
        var out: UInt = 0
        (data as NSData).getBytes(&out, length: MemoryLayout<UInt>.size)
        return out
    }
    
    func handleResponseBody(_ data: Data) {
        if let message = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
            self.delegate.handleBody(message)
        }
    }
    
    func connectTo(_ service: NetService) {
        service.delegate = self
        service.resolve(withTimeout: 15)
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
            self.devices.removeAll(keepingCapacity: true)
        }
        
        self.coServiceBrowser = NetServiceBrowser()
        self.coServiceBrowser.delegate = self
        self.coServiceBrowser.searchForServices(ofType: "_probonjore._tcp.", inDomain: "local.")
    }
    
    func send(_ data: Data) {
        print("send data")
        
        if let socket = self.getSelectedSocket() {
            var header = data.count
            let headerData = Data(bytes: &header, count: MemoryLayout<UInt>.size)
            socket.write(headerData, withTimeout: -1.0, tag: PacketTag.header.rawValue)
            socket.write(data, withTimeout: -1.0, tag: PacketTag.body.rawValue)
        }
    }
    
    func connectToServer(_ service: NetService) -> Bool {
        var connected = false
        
        let addresses: Array = service.addresses!
        var socket = self.sockets[service.name]
        
        if !(socket?.isConnected != nil) {
            socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
            
            while !connected && !addresses.isEmpty {
                let address: Data = addresses[0] 
                do {
                    if (try socket?.connect(toAddress: address) != nil) {
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
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("did resolve address \(sender.name)")
        if self.connectToServer(sender) {
            print("connected to \(sender.name)")
        }
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("net service did no resolve. errorDict: \(errorDict)")
    }   
    
    // MARK: GCDAsyncSocket Delegates
    
    func socket(_ sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        print("connected to host \(String(describing: host)), on port \(port)")
        sock.readData(toLength: UInt(MemoryLayout<UInt64>.size), withTimeout: -1.0, tag: 0)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket!, withError err: Error!) {
        print("socket did disconnect \(String(describing: sock)), error: \(String(describing: err._userInfo))")
    }
    
    func socket(_ sock: GCDAsyncSocket!, didRead data: Data!, withTag tag: Int) {
        print("socket did read data. tag: \(tag)")
        
        if self.getSelectedSocket() == sock {
            
            if data.count == MemoryLayout<UInt>.size {
                let bodyLength: UInt = self.parseHeader(data)
                sock.readData(toLength: bodyLength, withTimeout: -1, tag: PacketTag.body.rawValue)
            } else {
                self.handleResponseBody(data)
                sock.readData(toLength: UInt(MemoryLayout<UInt>.size), withTimeout: -1, tag: PacketTag.header.rawValue)
            }
        }
    }
    
    func socketDidCloseReadStream(_ sock: GCDAsyncSocket!) {
        print("socket did close read stream")
    }    
    
    // MARK: NSNetServiceBrowser Delegates
    
    func netServiceBrowser(_ aNetServiceBrowser: NetServiceBrowser, didFind aNetService: NetService, moreComing: Bool) {
        self.devices.append(aNetService)
        if !moreComing {
            self.delegate.didChangeServices()
        }
    }
    
    func netServiceBrowser(_ aNetServiceBrowser: NetServiceBrowser, didRemove aNetService: NetService, moreComing: Bool) {
        self.devices.removeObject(aNetService)
        if !moreComing {
            self.delegate.didChangeServices()            
        }
    }
    
    func netServiceBrowserDidStopSearch(_ aNetServiceBrowser: NetServiceBrowser) {
        self.stopBrowsing()
    }
    
    func netServiceBrowser(_ aNetServiceBrowser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
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
