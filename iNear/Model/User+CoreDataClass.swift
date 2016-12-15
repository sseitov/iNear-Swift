//
//  User+CoreDataClass.swift
//  iNear
//
//  Created by Сергей Сейтов on 09.12.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import Foundation
import CoreData
import SDWebImage
import CoreLocation
import Firebase

enum SocialType:Int16 {
    case unknown = 0
    case facebook = 1
    case google = 2
}

public class User: NSManagedObject {
    lazy var socialType: SocialType = {
        if let val = SocialType(rawValue: self.type) {
            return val
        } else {
            return .unknown
        }
    }()
    
    lazy var imageURL: URL? = {
        if self.image != nil {
            return URL(string: self.image!)
        } else {
            return nil
        }
    }()
    
    lazy var shortName:String = {
        if self.givenName != nil {
            return self.givenName!
        } else if self.name != nil {
            return self.name!
        } else {
            return "anonym"
        }
    }()
    
    func location() -> CLLocationCoordinate2D? {
        if latitude == 0 && longitude == 0 {
            return nil
        } else {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    func uploadToken(_ completion: @escaping() -> ()) {
        let ref = FIRDatabase.database().reference()
        ref.child("tokens").child(uid!).observeSingleEvent(of: .value, with: { snapshot in
            if let token = snapshot.value as? String {
                self.token = token
                Model.shared.saveContext()
            }
            completion()
        })
    }
    
    func uploadPosition(_ completion: @escaping(Bool) -> ()) {
        let ref = FIRDatabase.database().reference()
        ref.child("positions").child(uid!).observeSingleEvent(of: .value, with: { snaphot in
            if let data = snaphot.value as? [String:Any] {
                if let lat = data["latitude"] as? Double {
                    self.latitude = lat
                }
                if let lon = data["longitude"] as? Double {
                    self.longitude = lon
                }
                if let dateStr = data["lastDate"] as? String {
                    self.lastDate = Model.shared.dateFormatter.date(from: dateStr) as NSDate?
                }
                Model.shared.saveContext()
                completion(self.lastDate != nil)
            } else {
                completion(false)
            }
        })
    }

    func userData() -> [String:Any] {
        var profile:[String : Any] = ["socialType" : Int(type)]
        if email != nil {
            profile["email"] = email!
        }
        if name != nil {
            profile["name"] = name!
        }
        if givenName != nil {
            profile["givenName"] = givenName!
        }
        if familyName != nil {
            profile["familyName"] = familyName!
        }
        if image != nil {
            profile["imageURL"] = image!
        }

        return profile
    }
    
    func setUserData(_ profile:[String : Any], completion: @escaping() -> ()) {
        if let typeVal = profile["socialType"] as? Int {
            type = Int16(typeVal)
        } else {
            type = 0
        }
        email = profile["email"] as? String
        name = profile["name"] as? String
        givenName = profile["givenName"] as? String
        familyName = profile["familyName"] as? String

        image = profile["imageURL"] as? String
        if image != nil, let url = URL(string: image!) {
            SDWebImageManager.shared().downloadImage(with: url,
                                                     options: [],
                                                     progress: { _ in },
                                                     completed: { image, error, _, _, _ in
                                                        if image != nil {
                                                            self.imageData = UIImagePNGRepresentation(image!) as NSData?
                                                        }
                                                        Model.shared.saveContext()
                                                        completion()
            })
        } else {
            imageData = nil
            completion()
        }
    }

    func getImage() -> UIImage {
        if imageData != nil {
            return UIImage(data: imageData! as Data)!
        } else {
            return UIImage(named:"logo")!
        }
    }
}
