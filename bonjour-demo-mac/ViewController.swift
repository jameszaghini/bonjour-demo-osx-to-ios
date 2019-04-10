//
//  ViewController.swift
//  bonjour-demo-mac
//
//  Created by James Zaghini on 8/05/2015.
//  Copyright (c) 2015 James Zaghini. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, BonjourServerDelegate {
    
    private var bonjourServer: BonjourServer!
    
    @IBOutlet private var tableView: NSTableView!
    @IBOutlet private var toSendTextField: NSTextField!
    @IBOutlet private var readLabel: NSTextField!
    @IBOutlet private var sendButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        bonjourServer = BonjourServer()
        bonjourServer.delegate = self
    }
    
    // MARK: Bonjour server delegates
    
    func didChangeServices() {
        tableView.reloadData()
    }
    
    func connected() {
        
    }
    
    func disconnected() {
        
    }
    
    func handleBody(_ body: NSString?) {
        readLabel.stringValue = body! as String
    }
    
    // MARK: TableView Delegates

    func numberOfRows(in aTableView: NSTableView) -> Int {
        return bonjourServer.devices.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any?{
        var result = ""

        let columnIdentifier = tableColumn!.identifier.rawValue
        if columnIdentifier == "bonjour-device" {
            let device = bonjourServer.devices[row]
            result = device.name
        }
        return result
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        print("notification: \(String(describing: notification.userInfo))")

        if bonjourServer.devices.count > 0 {
            let service = bonjourServer.devices[tableView.selectedRow]
            bonjourServer.connectTo(service)
        }
    }

    // MARK: - Private

    @IBAction private func sendData(_ sender: NSButton) {
        if let data = toSendTextField.stringValue.data(using: String.Encoding.utf8) {
            bonjourServer.send(data)
        }
    }
}
