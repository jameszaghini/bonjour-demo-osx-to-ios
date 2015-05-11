//
//  ViewController.swift
//  bonjour-demo-mac
//
//  Created by James Zaghini on 8/05/2015.
//  Copyright (c) 2015 James Zaghini. All rights reserved.
//

import Cocoa

let headerTag = 1
let bodyTag = 2

class ViewController: NSViewController, NSNetServiceBrowserDelegate, NSNetServiceDelegate, GCDAsyncSocketDelegate, NSTableViewDelegate, NSTableViewDataSource {

    var coServiceBrowser: NSNetServiceBrowser!
    
    var devices: Array<NSNetService>!
    
    var sockets: [String : GCDAsyncSocket]!
    
    @IBOutlet var tableView: NSTableView!
    
    @IBOutlet var toSendTextField: NSTextField!
    
    @IBOutlet var readLabel: NSTextField!
    
    @IBOutlet var sendButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
            self.readLabel.stringValue = message as String
        }
    }
    
    @IBAction func sendData(sender: NSButton) {
        println("send data")
        
        if let data = self.toSendTextField.stringValue.dataUsingEncoding(NSUTF8StringEncoding) {
            if let socket = self.getSelectedSocket() {
                var header = data.length
                let headerData = NSData(bytes: &header, length: sizeof(UInt))
                socket.writeData(headerData, withTimeout: -1.0, tag: headerTag)
                socket.writeData(data, withTimeout: -1.0, tag: bodyTag)
            }
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
    
    func connectToServer(service: NSNetService) -> Bool {
        var connected = false
        
        let addresses: Array = service.addresses!
        var socket = self.sockets[service.name]
        
        if !(socket?.isConnected != nil) {
           socket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
           
            while !connected && Bool(addresses.count) {
                let address: NSData = addresses[0] as! NSData
                var error: NSError?
                if (socket?.connectToAddress(address, error: &error) != nil) {
                    self.sockets.updateValue(socket!, forKey: service.name)
                    connected = true
                }
            }
        }
        
        return true
    }
    
    // MARK: TableView Delegates

    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return self.devices.count
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject?{
        var result = ""
        
        var columnIdentifier = tableColumn!.identifier
        if columnIdentifier == "bonjour-device" {
            let device = self.devices[row]
            result = device.name
        }
        return result
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        println("notification: \(notification.userInfo)")

        if self.devices.count > 0 {
            let service = self.devices[self.tableView.selectedRow]
            service.delegate = self
            service.resolveWithTimeout(15)
        }
    }
    
    // MARK: NSNetService Delegates

    func netServiceDidResolveAddress(sender: NSNetService) {
        println("did resolve address \(sender.name)")
        if self.connectToServer(sender) {
            println("connected to \(sender.name)")
        }
    }
    
    func netService(sender: NSNetService, didNotResolve errorDict: [NSObject : AnyObject]) {
        println("net service did no resolve. errorDict: \(errorDict)")
    }
    
    // MARK: NSNetServiceBrowser Delegates
    
    func netServiceBrowser(aNetServiceBrowser: NSNetServiceBrowser, didFindService aNetService: NSNetService, moreComing: Bool) {
        self.devices.append(aNetService)
        if !moreComing {
            self.tableView.reloadData()
        }
    }
    
    func netServiceBrowser(aNetServiceBrowser: NSNetServiceBrowser, didRemoveService aNetService: NSNetService, moreComing: Bool) {
        self.devices.removeObject(aNetService)
        if !moreComing {
            self.tableView.reloadData()
        }
    }
    
    func netServiceBrowserDidStopSearch(aNetServiceBrowser: NSNetServiceBrowser) {
        self.stopBrowsing()
    }
    
    func netServiceBrowser(aNetServiceBrowser: NSNetServiceBrowser, didNotSearch errorDict: [NSObject : AnyObject]) {
        self.stopBrowsing()
    }
    
    // MARK: NSNetServiceBrowser helpers
    
    func stopBrowsing() {
        if self.coServiceBrowser != nil {
            self.coServiceBrowser.stop()
            self.coServiceBrowser.delegate = nil
            self.coServiceBrowser = nil
        }
    }
    
    // MARK: GCDAsyncSocket Delegates
    
    func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        println("connected to host \(host), on port \(port)")
        sock.readDataToLength(UInt(sizeof(UInt64)), withTimeout: -1.0, tag: 0)
    }
    
    func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        println("socket did disconnect \(sock), error: \(err.userInfo)")
    }
    
    func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        println("socket did read data. tag: \(tag)")
        
        if self.getSelectedSocket() == sock {
        
            if data.length == sizeof(UInt) {
                let bodyLength: UInt = self.parseHeader(data)
                sock.readDataToLength(bodyLength, withTimeout: -1, tag: bodyTag)
            } else {
                self.handleResponseBody(data)
                sock.readDataToLength(UInt(sizeof(UInt)), withTimeout: -1, tag: headerTag)
            }
        }
    }
    
    func socketDidCloseReadStream(sock: GCDAsyncSocket!) {
        println("socket did close read stream")
    }
    
    // MARK: helpers
    
    func getSelectedSocket() -> GCDAsyncSocket? {
        let service = self.devices[self.tableView.selectedRow]
        return self.sockets[service.name]!
    }
}

extension Array {
    mutating func removeObject<U: Equatable>(object: U) {
        var index: Int?
        for (idx, objectToCompare) in enumerate(self) {
            if let to = objectToCompare as? U {
                if object == to {
                    index = idx
                }
            }
        }
        
        if(index != nil) {
            self.removeAtIndex(index!)
        }
    }
}

