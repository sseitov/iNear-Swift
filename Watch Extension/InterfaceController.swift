//
//  InterfaceController.swift
//  Watch Extension
//
//  Created by Сергей Сейтов on 11.12.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class ContactController: NSObject {
    @IBOutlet var imageView: WKInterfaceImage!
    @IBOutlet var nameLabel: WKInterfaceLabel!
    
    var uid:String?
}

class Contact  {
    
    let uid:String
    var name:String?
    let image:UIImage?
    
    init(_ uid:String, name:String?, imageData:Data?) {
        self.uid = uid
        self.name = name
        if imageData != nil {
            self.image = UIImage(data: imageData!)
        } else {
            self.image = nil
        }
    }
}

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    @IBOutlet var contactsTable: WKInterfaceTable!
  
    private var session:WCSession?

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        if WCSession.isSupported() {
            session = WCSession.default()
            session!.delegate = self
            session!.activate()
        }
        refreshTable()
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }

    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        if session != nil {
            let row = contactsTable.rowController(at: rowIndex) as! ContactController
            session!.sendMessage(["userPosition" : row.uid!], replyHandler: { position in
                DispatchQueue.main.async {
                    if (position["userPoint"] as? [String:Any]) != nil {
                        let context:[String:Any] = ["user" : row.uid!, "position" : position]
                        self.pushController(withName: "Map", context: context)
                    } else {
                        self.presentAlert(withTitle: "Error",
                                          message: "User not published his location.",
                                          preferredStyle: .alert,
                                          actions: [
                                            WKAlertAction(title: "Ok", style: .default, handler: {})
                            ])
                    }
                }
            }, errorHandler: { error in
                DispatchQueue.main.async {
                    self.presentAlert(withTitle: "", message: "User not published his location.", preferredStyle: .alert, actions: [])
                }
            })
        }
    }

    func refreshTable() {
        let contacts = loadContacts()
        contactsTable.setNumberOfRows(contacts.count, withRowType: "contact")
        for index in 0..<contacts.count {
            let row = contactsTable.rowController(at:index) as! ContactController
            row.nameLabel.setText(contacts[index].name)
            row.imageView.setImage(contacts[index].image)
            row.uid = contacts[index].uid
        }
    }
    
    private func loadContacts() -> [Contact] {
        var contacts:[Contact] = []
        if let list = UserDefaults.standard.object(forKey: "contacts") as? [String:Any] {
            for (key, value) in list {
                if let data = value as? [String:Any] {
                    let user = Contact(key, name:(data["name"] as? String), imageData:(data["image"] as? Data))
                    contacts.append(user)
                }
            }
        }
        return contacts.sorted(by: { user1, user2 in
            if user1.name != nil && user2.name != nil {
                return user1.name! < user2.name!
            } else if user1.name == nil {
                return false
            } else {
                return true
            }
        })
    }
    
}

extension InterfaceController {
    
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate")
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("sessionReachabilityDidChange")
    }
    
    // Receiver
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        print("didReceiveApplicationContext")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("didReceiveMessage")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("didReceiveMessage replyHandler")
        if let list = message["contactList"] as? [Any] {
            var contacts:[Contact] = []
            for item in list {
                if let contact = item as? [String:Any] {
                    if let uid = contact["uid"] as? String {
                        let name = contact["name"] as? String
                        let imageData = contact["image"] as? Data
                        contacts.append(Contact(uid, name: name, imageData: imageData))
                    }
                }
            }
            replyHandler(["contactList":contacts.count])
            DispatchQueue.main.async {
                self.saveContacts(contacts)
                self.refreshTable()
            }
        } else {
            replyHandler(["contactList":false])
        }
    }
    
    private func saveContacts(_ contacts:[Contact]) {
        var list:[String:Any] = [:]
        for contact in contacts {
            var user:[String:Any] = [:]
            if contact.name != nil {
                user["name"] = contact.name!
            }
            if contact.image != nil {
                user["image"] = UIImagePNGRepresentation(contact.image!)
            }
            list[contact.uid] = user
        }
        UserDefaults.standard.set(list, forKey: "contacts")
        UserDefaults.standard.synchronize()
    }

}
