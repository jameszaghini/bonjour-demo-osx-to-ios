//
//  ViewController.swift
//  bonjour-demo-mac
//
//  Created by James Zaghini on 8/05/2015.
//  Copyright (c) 2015 James Zaghini. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, BonjourServerDelegate {
    
    var bonjourServer: BonjourServer!
    
    @IBOutlet var tableView: NSTableView!
    
    @IBOutlet var toSendTextField: NSTextField!
    
    @IBOutlet var readLabel: NSTextField!
    
    @IBOutlet var sendButton: NSButton!
        
    @IBAction func sendData(sender: NSButton) {
        if let data = self.toSendTextField.stringValue.dataUsingEncoding(NSUTF8StringEncoding) {
            self.bonjourServer.send(data)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bonjourServer = BonjourServer()
        self.bonjourServer.delegate = self
    }
    
    // MARK: Bonjour server delegates
    
    func didChangeServices() {
        self.tableView.reloadData()
    }
    
    func connected() {
        
    }
    
    func disconnected() {
        
    }
    
    func handleBody(body: NSString?) {
        self.readLabel.stringValue = body! as String
    }
    
    // MARK: TableView Delegates

    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return bonjourServer.devices.count
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject?{
        var result = ""
        
        let columnIdentifier = tableColumn!.identifier
        if columnIdentifier == "bonjour-device" {
            let device = self.bonjourServer.devices[row]
            result = device.name
        }
        return result
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        print("notification: \(notification.userInfo)")

        if self.bonjourServer.devices.count > 0 {
            let service = self.bonjourServer.devices[self.tableView.selectedRow]
            self.bonjourServer.connectTo(service)
        }
    }
}
