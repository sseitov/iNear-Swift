//
//  Model.swift
//  iNear
//
//  Created by Сергей Сейтов on 09.12.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import Foundation
import CoreData
import Firebase

enum SocialType:Int {
    case unknown = 0
    case facebook = 1
    case twitter = 2
    case google = 3
    case phone = 4
}

class Model : NSObject {
    
    static let shared = Model()
    
    // MARK: - SignOut from cloud
    
    func signOut() {
        if currentUser() != nil {
            switch currentUser()!.socialType {
            case .google:
                GIDSignIn.sharedInstance().signOut()
            case .facebook:
                FBSDKLoginManager().logOut()
            default:
                break
            }
        }
        try? FIRAuth.auth()?.signOut()
    }

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
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
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
    
    func updateUser(_ user:User) {
        saveContext()
        let ref = FIRDatabase.database().reference()
        ref.child("users").child(user.uid!).setValue(user.userData())
    }

    func setFacebookUser(_ user:FIRUser, profile:[String:Any]) {
        let cashedUser = createUser(user.uid)
        cashedUser.type = Int16(SocialType.facebook.rawValue)
        cashedUser.email = profile["email"] as? String
        cashedUser.name = profile["name"] as? String
        cashedUser.givenName = profile["first_name"] as? String
        cashedUser.familyName = profile["last_name"] as? String
        if let picture = profile["picture"] as? [String:Any] {
            if let data = picture["data"] as? [String:Any] {
                cashedUser.image = data["url"] as? String
            }
        }
        updateUser(cashedUser)
    }
    
    func setGoogleUser(_ user:FIRUser, googleProfile: GIDProfileData!) {
        let cashedUser = createUser(user.uid)
        cashedUser.type = Int16(SocialType.google.rawValue)
        cashedUser.email = googleProfile.email
        cashedUser.name = googleProfile.name
        cashedUser.givenName = googleProfile.givenName
        cashedUser.familyName = googleProfile.familyName
        if googleProfile.hasImage {
            if let url = googleProfile.imageURL(withDimension: 100) {
                cashedUser.image = url.absoluteString
            }
        }
        updateUser(cashedUser)
    }
    
    func currentUser() -> User? {
        if FIRAuth.auth()?.currentUser != nil {
            return getUser(FIRAuth.auth()!.currentUser!.uid)
        } else {
            return nil
        }
    }

    func allUsers() -> [User] {
        if FIRAuth.auth()?.currentUser == nil {
            return[]
        }
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        let predicate = NSPredicate(format: "uid != %@", currentUser()!.uid!)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "familyName", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let all = try? managedObjectContext.fetch(fetchRequest) as! [User] {
            return all
        } else {
            return []
        }
    }

}
