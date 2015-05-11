//
//  ViewController.swift
//
//  Created by James Zaghini on 6/05/2015.
//  Copyright (c) 2015 James Zaghini. All rights reserved.
//

import UIKit

let headerTag = 1
let bodyTag = 2

class ViewController: UIViewController, NSNetServiceDelegate, NSNetServiceBrowserDelegate, GCDAsyncSocketDelegate {
    
    var service: NSNetService!
    
    var socket: GCDAsyncSocket!
    
    @IBOutlet var toSendTextField: UITextField!
    
    @IBOutlet var sendButton: UIButton!
    
    @IBOutlet var receivedTextField: UITextField!
    
    @IBOutlet var connectedToLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.startBroadCasting()
    }

    func startBroadCasting() {
        self.socket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        var error: NSError?
        if self.socket.acceptOnPort(0, error: &error) {
            self.service = NSNetService(domain: "local.", type: "_probonjore._tcp.", name: UIDevice.currentDevice().name, port: Int32(self.socket.localPort))
            self.service.delegate = self
            self.service.publish()
        } else {
            println("Unable to create socket. Error \(error)")
        }
    }
    
    func connectedToDevice() {
        self.connectedToLabel.text = "Connected to " + self.service.name

    }
    
    func disconnectedFromDevice() {
        self.connectedToLabel.text = "Disconnected"
    }
    
    func parseHeader(data: NSData) -> UInt {
        var out: UInt = 0
        data.getBytes(&out, length: sizeof(UInt))
        return out
    }
    
    func handleResponseBody(data: NSData) {
        if let message = NSString(data: data, encoding: NSUTF8StringEncoding) {
            self.receivedTextField.text = message as String
        }
    }
    
    @IBAction func sendText() {
        let data = self.toSendTextField.text.dataUsingEncoding(NSUTF8StringEncoding)

        var header = data!.length
        let headerData = NSData(bytes: &header, length: sizeof(UInt))
        self.socket.writeData(headerData, withTimeout: -1.0, tag: headerTag)
        
        self.socket.writeData(data, withTimeout: -1.0, tag: bodyTag)
    }
    
    /// MARK: NSNetService Delegates
    
    func netServiceDidPublish(sender: NSNetService) {
        println("Bonjour service published. domain: \(sender.domain), type: \(sender.type), name: \(sender.name), port: \(sender.port)")
    }
    
    func netService(sender: NSNetService, didNotPublish errorDict: [NSObject : AnyObject]) {
        println("Unable to create socket. domain: \(sender.domain), type: \(sender.type), name: \(sender.name), port: \(sender.port), Error \(errorDict)")
    }
    
    /// MARK: GCDAsyncSocket Delegates

    func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        println("Did accept new socket")
        self.socket = newSocket

        self.socket.readDataToLength(UInt(sizeof(UInt64)), withTimeout: -1.0, tag: 0)
        self.connectedToDevice()
    }
    
    func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        println("socket did disconnect: error \(err)")
        if self.socket == socket {
            self.disconnectedFromDevice()
        }
    }
    
    func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        println("did read data")
        
        if data.length == sizeof(UInt) {
            let bodyLength: UInt = self.parseHeader(data)
            sock.readDataToLength(bodyLength, withTimeout: -1, tag: bodyTag)
        } else {
            self.handleResponseBody(data)
            sock.readDataToLength(UInt(sizeof(UInt)), withTimeout: -1, tag: headerTag)
        }
    }
    
    func socket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
        println("did write data with tag: \(tag)")
    }
}

