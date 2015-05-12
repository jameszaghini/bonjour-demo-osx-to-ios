//
//  ViewController.swift
//
//  Created by James Zaghini on 6/05/2015.
//  Copyright (c) 2015 James Zaghini. All rights reserved.
//

import UIKit

class ViewController: UIViewController, BonjourControllerDelegate {
    
    var bonjourController: BonjourController!
    
    @IBOutlet var toSendTextField: UITextField!
    
    @IBOutlet var sendButton: UIButton!
    
    @IBOutlet var receivedTextField: UITextField!
    
    @IBOutlet var connectedToLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bonjourController = BonjourController()
        self.bonjourController.delegate = self
    }
    
    func connected() {
        self.connectedToLabel.text = "Connected to "
    }
    
    func disconnected() {
        self.connectedToLabel.text = "Disconnected"
    }
    
    func handleBody(body: NSString?) {
        self.receivedTextField.text = body as! String
    }

    func handleHeader(header: UInt) {
        
    }
    
    @IBAction func sendText() {
        if let data = self.toSendTextField.text.dataUsingEncoding(NSUTF8StringEncoding) {
            self.bonjourController.send(data)
        }
    }
}

