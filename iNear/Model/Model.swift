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
    
    func setEmailUser(_ user:FIRUser, email:String, result:@escaping (Bool) -> ()) {
        let cashedUser = createUser(user.uid)
        cashedUser.email = email
        updateUser(cashedUser, success: { success in
            if success {
                self.saveContext()
            }
            result(success)
        })
    }
    
    func createUser(_ uid:String) -> User {
        var user = getUser(uid)
        if user == nil {
            user = NSEntityDescription.insertNewObject(forEntityName: "User", into: managedObjectContext) as? User
            user!.uid = uid
        }
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
    
    func allUsers() -> [User] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        if FIRAuth.auth()?.currentUser != nil {
            let predicate = NSPredicate(format: "uid != %@", FIRAuth.auth()!.currentUser!.uid)
            fetchRequest.predicate = predicate
        }
        let sortDescriptor = NSSortDescriptor(key: "nickName", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let all = try? managedObjectContext.fetch(fetchRequest) as! [User] {
            return all
        } else {
            return []
        }
    }

    func updateUser(_ user:User, success:@escaping (Bool) -> ()) {
        saveContext()
        user.userData({ data in
            if data != nil {
                let ref = FIRDatabase.database().reference()
                ref.child("users").child(user.uid!).setValue(data!)
                success(true)
            } else {
                success(false)
            }
        })
    }

    func fetchUser(_ user:User, result:@escaping (Bool) -> ()) {
        let ref = FIRDatabase.database().reference()
        ref.child("users").child(user.uid!).observeSingleEvent(of: .value, with: { (snapshot) in
            if let profile = snapshot.value as? [String:Any] {
                user.setUserData(profile, completion: {
                    result(true)
                })
            } else {
                result(false)
            }
        }) { error in
            result(false)
        }
    }
}
