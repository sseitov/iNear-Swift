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
/*
        let contacts = Model.shared.allUsers()
        for contact in contacts {
            if !contact.uploadedOnWatch {
                contact.getImage({ image in
                    let data = UIImagePNGRepresentation(image.inCircle())
                    let friend:[String:Any] = ["uid" : contact.uid!, "name" : contact.name!, "image" : data!]
                    self.watchSession!.sendMessage(friend, replyHandler: { reply in
                        DispatchQueue.main.async {
                            if let uid = reply["uid"] as? String, uid == contact.uid! {
                                contact.uploadedOnWatch = true
                                Model.shared.saveContext()
                            }
                        }
                    }, errorHandler: { error in
                        print(error)
                    })
                })
            }
        }
 */
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
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("didReceiveMessage")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("didReceiveMessage replyHandler")
        if let task = message["task"] as? String {
            if task == "contactList" {
                DispatchQueue.main.async {
                    var contacts:[Any] = []
                    let users = Model.shared.allUsers()
                    for user in users {
                        let imageData = UIImagePNGRepresentation(user.getImage().inCircle())
                        let contact:[String:Any] = ["uid" : user.uid!, "name" : user.name!, "image" : imageData!]
                        contacts.append(contact)
                    }
                    replyHandler(["contacts" : contacts])
                }
                return
            } else if task == "userPosition" {
                DispatchQueue.main.async {
                    if let uid = message["user"] as? String, let user = Model.shared.getUser(uid) {
                        replyHandler(["latitude" : user.latitude, "longitude" : user.longitude])
                    } else {
                        replyHandler([:])
                    }
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
