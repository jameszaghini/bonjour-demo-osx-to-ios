//
//  ViewController.swift
//
//  Created by James Zaghini on 6/05/2015.
//  Copyright (c) 2015 James Zaghini. All rights reserved.
//

import UIKit

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
    
    @IBAction func sendText() {
        if let data = self.toSendTextField.text.dataUsingEncoding(NSUTF8StringEncoding) {
            self.socket.writeData(data, withTimeout: -1.0, tag: 0)
        }
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
        if let message = NSString(data: data, encoding: NSUTF8StringEncoding) {
            self.receivedTextField.text = message as String
        }
    }
    
    func socket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
        println("did write data with tag: \(tag)")
    }
}

