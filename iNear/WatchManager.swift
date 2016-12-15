//
//  WatchManager.swift
//  iNear
//
//  Created by Сергей Сейтов on 12.12.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import UIKit
import WatchConnectivity

class WatchManager: NSObject, WCSessionDelegate {
    
    static let shared = WatchManager()
    var watchSession:WCSession?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            watchSession = WCSession.default()
        }
    }
    
    func activate() -> Bool {
        if watchSession != nil {
            watchSession!.delegate = self
            watchSession!.activate()
            return true
        } else {
            return false
        }
    }
    
    func updateContacts() {
        if watchSession != nil {
            let contacts = Model.shared.allContacts()
            var friends:[Any] = []
            for contact in contacts {
                let data = UIImagePNGRepresentation(contact.getImage().withSize(CGSize(width: 30, height: 30)).inCircle())
                let friend:[String:Any] = ["uid" : contact.uid!, "name" : contact.name!, "image" : data!]
                friends.append(friend)
            }
            try? watchSession!.updateApplicationContext(["contactList" : friends])
        }
    }
}

extension WatchManager {
   
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith \(activationState)")
        DispatchQueue.main.async {
            self.updateContacts()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("didReceiveMessage")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let task = message["task"] as? String {
            if task == "contactList" {
                var contacts:[Any] = []
                let users = Model.shared.allContacts()
                for user in users {
                    let imageData = UIImagePNGRepresentation(user.getImage().withSize(CGSize(width: 30, height: 30)).inCircle())
                    let contact:[String:Any] = ["uid" : user.uid!, "name" : user.shortName, "image" : imageData!]
                    contacts.append(contact)
                }
                replyHandler(["contacts" : contacts])
                return
            } else if task == "userPosition" {
                if let uid = message["user"] as? String, let user = Model.shared.getUser(uid) {
                    replyHandler(["latitude" : user.latitude, "longitude" : user.longitude])
                } else {
                    replyHandler([:])
                }
                return
            }
        }
        replyHandler([:])
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("sessionReachabilityDidChange")
    }
    
}
