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
  
    private let session: WCSession = WCSession.default()

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        session.delegate = self
        session.activate()
        refreshTable()
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }

    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let row = contactsTable.rowController(at: rowIndex) as! ContactController
        session.sendMessage(["task" : "userPosition", "user" : row.uid!], replyHandler: { position in
            DispatchQueue.main.async {
                self.pushController(withName: "Map", context: position)
            }
        }, errorHandler: { error in
            print(error)
            self.presentAlert(withTitle: "", message: "User not published his location.", preferredStyle: .alert, actions: [])
        })
    }
    
    func refreshTable() {
        let contacts = allContacts()
        contactsTable.setNumberOfRows(contacts.count, withRowType: "contact")
        for index in 0..<contacts.count {
            let row = contactsTable.rowController(at:index) as! ContactController
            row.nameLabel.setText(contacts[index].name)
            row.imageView.setImage(contacts[index].image)
            row.uid = contacts[index].uid
        }
    }
    
    private func allContacts() -> [Contact] {
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
    
    func addContact(_ contact:[String:Any]?) {
        if contact != nil, let uid = contact!["uid"] as? String {
            var list = UserDefaults.standard.object(forKey: "contacts") as? [String:Any]
            var user:[String:Any] = [:]
            if let name = contact!["name"] as? String {
                user["name"] = name
            }
            if let imageData = contact!["image"] as? Data {
                user["image"] = imageData
            }
            if list == nil {
                list = [uid:user]
            } else {
                list![uid] = user
            }
            UserDefaults.standard.set(list, forKey: "contacts")
            UserDefaults.standard.synchronize()
        }
    }
}

extension InterfaceController {
    
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith")
        if session.isReachable {
            session.sendMessage(["task" : "contactList"], replyHandler: { list in
                if let contacts = list["contacts"] as? [Any]{
                    for contact in contacts {
                        self.addContact(contact as? [String:Any])
                    }
                }
                DispatchQueue.main.async {
                    self.refreshTable()
                }
            }, errorHandler: { error in
                print(error)
            })
        }
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
        if let list = applicationContext["contactList"] as? [Any] {
            DispatchQueue.main.async {
                UserDefaults.standard.removeObject(forKey: "contacts")
                for contact in list {
                    self.addContact(contact as? [String:Any])
                }
                self.refreshTable()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("didReceiveMessage")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("didReceiveMessage replyHandler")
    }

}
