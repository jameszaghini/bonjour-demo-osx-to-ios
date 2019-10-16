//
//  ViewController.swift
//
//  Created by James Zaghini on 6/05/2015.
//  Copyright (c) 2015 James Zaghini. All rights reserved.
//

import UIKit

class ViewController: UIViewController, BonjourClientDelegate {
    
    private var bonjourClient: BonjourClient!
    
    @IBOutlet private var toSendTextField: UITextField!
    @IBOutlet private var sendButton: UIButton!
    @IBOutlet private var receivedTextField: UITextField!
    @IBOutlet private var connectedToLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bonjourClient = BonjourClient()
        bonjourClient.delegate = self
    }
    
    func connectedTo(_ socket: GCDAsyncSocket!) {
        connectedToLabel.text = "Connected to " + (socket.connectedHost ?? "-")
    }
    
    func disconnected() {
        connectedToLabel.text = "Disconnected"
    }
    
    func handleBody(_ body: NSString?) {
        receivedTextField.text = body as String?
    }

    func handleHeader(_ header: UInt) {
        
    }
    
    @IBAction func sendText() {
        if let data = toSendTextField.text!.data(using: String.Encoding.utf8) {
            bonjourClient.send(data)
        }
    }
}

