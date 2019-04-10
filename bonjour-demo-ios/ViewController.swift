//
//  ViewController.swift
//
//  Created by James Zaghini on 6/05/2015.
//  Copyright (c) 2015 James Zaghini. All rights reserved.
//

import UIKit

class ViewController: UIViewController, BonjourClientDelegate {
    
    var bonjourClient: BonjourClient!
    
    @IBOutlet var toSendTextField: UITextField!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var receivedTextField: UITextField!
    @IBOutlet var connectedToLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bonjourClient = BonjourClient()
        self.bonjourClient.delegate = self
    }
    
    func connectedTo(_ socket: GCDAsyncSocket!) {
        self.connectedToLabel.text = "Connected to " + socket.connectedHost
    }
    
    func disconnected() {
        self.connectedToLabel.text = "Disconnected"
    }
    
    func handleBody(_ body: NSString?) {
        self.receivedTextField.text = body as String?
    }

    func handleHeader(_ header: UInt) {
        
    }
    
    @IBAction func sendText() {
        if let data = self.toSendTextField.text!.data(using: String.Encoding.utf8) {
            self.bonjourClient.send(data)
        }
    }
}

