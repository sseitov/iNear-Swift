//
//  User+CoreDataClass.swift
//  iNear
//
//  Created by Сергей Сейтов on 28.11.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import Foundation
import CoreData
import Firebase

public class User: NSManagedObject {
    
    func userData(_ userData:@escaping ([String:Any]?) -> ()) {
        var profile:[String : Any] = ["email" : email!]
        if nickName != nil {
            profile["nickName"] = nickName!
        }
        
        if imageData != nil {
            let meta = FIRStorageMetadata()
            meta.contentType = "image/jpeg"
            Model.shared.storageRef.child(uid!).put(imageData! as Data, metadata: meta, completion: { metadata, error in
                if error != nil {
                    userData(nil)
                } else {
                    self.imageURL = metadata?.path!
                    Model.shared.saveContext()
                    profile["imageURL"] = self.imageURL!
                    userData(profile)
                }
            })
        } else {
            if imageURL != nil {
                let ref = Model.shared.storageRef.child(imageURL!)
                ref.delete(completion: { error in
                    self.imageURL = nil
                    Model.shared.saveContext()
                    userData(profile)
                })
            } else {
                userData(profile)
            }
        }
    }
    
    func setUserData(_ profile:[String : Any], completion:@escaping () -> ()) {
        email = profile["email"] as? String
        nickName = profile["nickName"] as? String
        imageURL = profile["imageURL"] as? String
        if imageURL != nil {
            let ref = Model.shared.storageRef.child(imageURL!)
            ref.data(withMaxSize: INT64_MAX, completion: { data, error in
                self.imageData = data as NSData?
                Model.shared.saveContext()
                completion()
            })
        } else {
            Model.shared.saveContext()
            completion()
        }
    }

}
