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
import AFNetworking
import SDWebImage

enum SocialType:Int {
    case unknown = 0
    case facebook = 1
    case twitter = 2
    case google = 3
    case phone = 4
}

enum PushType:Int {
    case none = 0
    case newCoordinate = 1
    case newMessage = 2
}

let newMessageNotification = Notification.Name("NEW_MESSAGE")
let readMessageNotification = Notification.Name("READ_MESSAGE")

class Model : NSObject {
    
    static let shared = Model()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Date formatter
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()
    
    lazy var textDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    lazy var textYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

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
        newMessageRefHandle = nil
    }
    
    // MARK: - Cloud observers
    
    func startObservers() {
        if newMessageRefHandle == nil {
            observeMessages()
        }
    }
    
    lazy var storageRef: FIRStorageReference = FIRStorage.storage().reference(forURL: "gs://v-channel-a693c.appspot.com")
    
    static let serverKey = "AAAA7y6lzqU:APA91bF0ISTVkscUz81T0fYnLvEQzqGPOIerVudF7_CIj4eJsSs1P1FIw4KYzx8MNo11kF7WgZ6SGT3DZuyCNtuIQMi7JxInttd6vf3JmAkxvqPrVzd_6PyXWxW9IoRYQP5aRkZvzwrelpkVa4xUCkGFOkxDdKNVlQ"
    
    private var newMessageRefHandle: FIRDatabaseHandle?

    // MARK: - Push notifications
    
    fileprivate lazy var httpManager:AFHTTPSessionManager = {
        let manager = AFHTTPSessionManager(baseURL: URL(string: "https://fcm.googleapis.com/fcm/"))
        manager.requestSerializer = AFJSONRequestSerializer()
        manager.requestSerializer.setValue("application/json", forHTTPHeaderField: "Content-Type")
        manager.requestSerializer.setValue("key=\(serverKey)", forHTTPHeaderField: "Authorization")
        manager.responseSerializer = AFHTTPResponseSerializer()
        return manager
    }()
    
    fileprivate func messagePush(_ text:String?, to:User, from:User) {
        if to.token != nil {
            let data:[String:Int] = ["pushType" : PushType.newMessage.rawValue]
            let notification:[String:Any] = ["title" : "New message from \(from.shortName):",
                "body": text != nil ? text! : "It is photo",
                "sound":"default",
                "content_available": true]
            let message:[String:Any] = ["to" : to.token!, "priority" : "high", "notification" : notification, "data" : data]
            httpManager.post("send", parameters: message, progress: nil, success: { task, response in
            }, failure: { task, error in
                print("SEND PUSH ERROR: \(error)")
            })
        } else {
            print("USER HAVE NO TOKEN")
        }
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
    
    func deleteUser(_ user:User) {
        managedObjectContext.delete(user)
        saveContext()
    }
    
    func updateUser(_ user:User) {
        saveContext()
        let ref = FIRDatabase.database().reference()
        ref.child("users").child(user.uid!).setValue(user.userData())
    }
    
    func refreshUser(_ user:User, completion: @escaping() -> ()) {
        let ref = FIRDatabase.database().reference()
        let userQuery = ref.child("users").child(user.uid!)
        userQuery.observeSingleEvent(of: .value, with: { snapshot in
            if let profile = snapshot.value as? [String:Any] {
                user.token = profile["token"] as? String
                if let lat = profile["latitude"] as? Double, let lon = profile["longitude"] as? Double, let date = profile["lastDate"] as? String {
                    user.latitude = lat
                    user.longitude = lon
                    user.lastDate = self.dateFormatter.date(from: date) as NSDate?
                    self.saveContext()
                }
            }
            completion()
        })
    }
    
    func setFacebookUser(_ user:FIRUser, profile:[String:Any], completion: @escaping() -> ()) {
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
        if cashedUser.image != nil, let url = URL(string: cashedUser.image!) {
            SDWebImageManager.shared().downloadImage(with: url,
                                                     options: [],
                                                     progress: { _ in },
                                                     completed: { image, error, _, _, _ in
                                                        if image != nil {
                                                            cashedUser.imageData = UIImagePNGRepresentation(image!) as NSData?
                                                        }
                                                        self.updateUser(cashedUser)
                                                        completion()
            })
        } else {
            cashedUser.imageData = nil
            updateUser(cashedUser)
            completion()
        }
    }
    
    func setGoogleUser(_ user:FIRUser, googleProfile: GIDProfileData!, completion: @escaping() -> ()) {
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
        if cashedUser.image != nil, let url = URL(string: cashedUser.image!) {
            SDWebImageManager.shared().downloadImage(with: url,
                                                     options: [],
                                                     progress: { _ in },
                                                     completed: { image, error, _, _, _ in
                                                        if image != nil {
                                                            cashedUser.imageData = UIImagePNGRepresentation(image!) as NSData?
                                                        }
                                                        self.updateUser(cashedUser)
                                                        completion()
            })
        } else {
            cashedUser.imageData = nil
            updateUser(cashedUser)
            completion()
        }
    }
    
    func currentUser() -> User? {
        if FIRAuth.auth()?.currentUser != nil {
            return getUser(FIRAuth.auth()!.currentUser!.uid)
        } else {
            return nil
        }
    }

    func allUsers() -> [User] {
        if currentUser() == nil {
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
    
    // MARK: - Message table
    
    func createMessage(_ uid:String) -> Message {
        var message = getMessage(uid)
        if message == nil {
            message = NSEntityDescription.insertNewObject(forEntityName: "Message", into: managedObjectContext) as? Message
            message!.uid = uid
        }
        return message!
    }
    
    func getMessage(_ uid:String) -> Message? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
        let predicate = NSPredicate(format: "uid = %@", uid)
        fetchRequest.predicate = predicate
        if let message = try? managedObjectContext.fetch(fetchRequest).first as? Message {
            return message
        } else {
            return nil
        }
    }
    
    private func chatPredicate(with:String) -> NSPredicate {
        let predicate1  = NSPredicate(format: "from == %@", with)
        let predicate2 = NSPredicate(format: "to == %@", currentUser()!.uid!)
        let toPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, predicate2])
        let predicate3  = NSPredicate(format: "from == %@", currentUser()!.uid!)
        let predicate4 = NSPredicate(format: "to == %@", with)
        let fromPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate3, predicate4])
        return NSCompoundPredicate(orPredicateWithSubpredicates: [toPredicate, fromPredicate])
    }
    
    func chatMessages(with:String) -> [Message] {
        if currentUser() == nil {
            return []
        }
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
        fetchRequest.predicate = chatPredicate(with: with)
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let all = try? managedObjectContext.fetch(fetchRequest) as! [Message] {
            return all
        } else {
            return []
        }
    }
    
    func unreadCountInChat(_ uid:String) -> Int {
        if currentUser() == nil {
            return 0
        }
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
        let predicate = NSPredicate(format: "isNew == YES")
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [chatPredicate(with: uid), predicate])
        
        do {
            return try managedObjectContext.count(for: fetchRequest)
        } catch {
            return 0
        }
    }
    
    func lastMessageInChat(_ uid:String) -> Message? {
        if currentUser() == nil {
            return nil
        }
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
        fetchRequest.predicate = chatPredicate(with: uid)
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.fetchLimit = 1
        if let all = try? managedObjectContext.fetch(fetchRequest) as! [Message] {
            return all.first
        } else {
            return nil
        }
    }
    
    func allUnreadCount() -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
        fetchRequest.predicate = NSPredicate(format: "isNew == YES")
        do {
            return try managedObjectContext.count(for: fetchRequest)
        } catch {
            return 0
        }
    }
    
    func readMessage(_ message:Message) {
        message.isNew = false
        saveContext()
        NotificationCenter.default.post(name: readMessageNotification, object: message)
    }
    
    func sendTextMessage(_ text:String, from:String, to:String) {
        let ref = FIRDatabase.database().reference()
        let dateStr = dateFormatter.string(from: Date())
        let messageItem = ["from" : from, "to" : to, "text" : text, "date" : dateStr]
        ref.child("messages").childByAutoId().setValue(messageItem)
        
        if let fromUser = getUser(from), let toUser = getUser(to) {
            self.messagePush(text, to: toUser, from: fromUser)
        }
    }
    
    func sendImageMessage(_ image:UIImage, from:String, to:String, result:@escaping (NSError?) -> ()) {
        if let imageData = UIImageJPEGRepresentation(image, 0.5) {
            let meta = FIRStorageMetadata()
            meta.contentType = "image/jpeg"
            self.storageRef.child(generateUDID()).put(imageData, metadata: meta, completion: { metadata, error in
                if error != nil {
                    result(error as NSError?)
                } else {
                    let ref = FIRDatabase.database().reference()
                    let dateStr = self.dateFormatter.string(from: Date())
                    let messageItem = ["from" : from, "to" : to, "image" : metadata?.path!, "date" : dateStr]
                    ref.child("messages").childByAutoId().setValue(messageItem)
                    
                    if let fromUser = self.getUser(from), let toUser = self.getUser(to) {
                        self.messagePush(nil, to: toUser, from: fromUser)
                    }
                    
                    result(nil)
                }
            })
        }
    }
    
    private func observeMessages() {
        let ref = FIRDatabase.database().reference()
        let messageQuery = ref.child("messages").queryLimited(toLast:25)
        
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            let messageData = snapshot.value as! [String:Any]
            if let from = messageData["from"] as? String, let to = messageData["to"] as? String {
                if self.currentUser() != nil && self.getMessage(snapshot.key) == nil {
                    let received = (to == self.currentUser()!.uid!)
                    let sended = (from == self.currentUser()!.uid!)
                    if received || sended {
                        let message = self.createMessage(snapshot.key)
                        message.setData(messageData, new: received, completion: {
                            NotificationCenter.default.post(name: newMessageNotification, object: message)
                        })
                    }
                }
            } else {
                print("Error! Could not decode message data")
            }
        })
    }
    
    func refreshMessages() {
        let ref = FIRDatabase.database().reference()
        ref.child("messages").queryOrdered(byChild: "date").observeSingleEvent(of: .value, with: { snapshot in
            if let values = snapshot.value as? [String:Any] {
                for (key, value) in values {
                    let messageData = value as! [String:Any]
                    if let from = messageData["from"] as? String, let to = messageData["to"] as? String {
                        if self.currentUser() != nil && self.getMessage(snapshot.key) == nil {
                            let received = (to == self.currentUser()!.uid!)
                            let sended = (from == self.currentUser()!.uid!)
                            if received || sended {
                                let message = self.createMessage(key)
                                message.setData(messageData, new: false, completion: {
                                    NotificationCenter.default.post(name: newMessageNotification, object: message)
                                })
                            }
                        }
                    } else {
                        print("Error! Could not decode message data")
                    }
                }
            }
        })
    }

}
