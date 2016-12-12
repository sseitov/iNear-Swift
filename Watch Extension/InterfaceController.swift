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

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    @IBOutlet var contactsTable: WKInterfaceTable!
  
    private let session: WCSession = WCSession.default()

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        session.delegate = self
        session.activate()
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
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
        DispatchQueue.main.async {
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("didReceiveMessage")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("didReceiveMessage \(message)")
        replyHandler(["result" : "success"])
    }

}
