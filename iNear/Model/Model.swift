//
//  Model.swift
//  iNear
//
//  Created by Сергей Сейтов on 21.11.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import UIKit
import CoreData
import Firebase

class Model : NSObject {
    
    static let shared = Model()
    
    lazy var storageRef: FIRStorageReference = FIRStorage.storage().reference(forURL: "gs://v-channel-a693c.appspot.com")
    
    // MARK: - CoreData stack
    
    lazy var applicationDocumentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "iNear", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("iNear.sqlite")
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: [NSMigratePersistentStoresAutomaticallyOption: true,NSInferMappingModelAutomaticallyOption: true])
        } catch {
            print("CoreData data error: \(error)")
        }
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                print("Saved data error: \(error)")
            }
        }
    }
    
    // MARK: - User table
    
    func createUser(_ uid:String, email:String) -> User {
        var user = getUser(uid)
        if user == nil {
            user = NSEntityDescription.insertNewObject(forEntityName: "User", into: managedObjectContext) as? User
            user!.uid = uid
        }
        
        let ref = FIRDatabase.database().reference()
        let data = ["email" : email]
        user!.email = email
        ref.child("users").child(uid).setValue(data)

        saveContext()
        return user!
    }
    
    func getUser(_ uid:String) -> User? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        let predicate = NSPredicate(format: "uid = %@", uid)
        fetchRequest.predicate = predicate
        if let user = try? managedObjectContext.fetch(fetchRequest).first as? User {
            return user
        } else {
            return nil
        }
    }
    
    func fetchUser(_ uid:String, result:@escaping (NSError?, [String:Any]?) -> ()) {
        let ref = FIRDatabase.database().reference()
        ref.child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            result(nil, snapshot.value as? [String:Any])
        }) { error in
            result(error as NSError?, nil)
        }
    }
    
    func updateUser(_ uid:String, nickName:String, imageData:NSData?, result:@escaping (NSError?) -> ()) {
        let ref = FIRDatabase.database().reference()
        fetchUser(uid, result: { error, data in
            if error == nil {
                var userData = data!
                userData["nickName"] = nickName
                if imageData != nil {
                    let meta = FIRStorageMetadata()
                    meta.contentType = "image/jpeg"
                    self.storageRef.child(uid).put(imageData as! Data, metadata: meta, completion: { metadata, error in
                        if error != nil {
                            result(error as NSError?)
                        } else {
                            userData["image"] = metadata?.path
                            ref.child("users").child(uid).setValue(userData)
                            result(nil)
                        }
                    })
                } else {
                    ref.child("users").child(uid).setValue(userData)
                    result(nil)
                }
            } else {
                result(error as NSError?)
            }
        })
    }
}
