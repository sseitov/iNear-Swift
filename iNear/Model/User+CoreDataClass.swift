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

public class User: NSManagedObject {
    lazy var socialType: SocialType = {
        if let val = SocialType(rawValue: Int(self.type)) {
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
    
    func location() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func userData() -> [String:Any] {
        var profile:[String : Any] = ["socialType" : Int(type), "latitude" : latitude, "longitude" : longitude]
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
        if token != nil {
            profile["token"] = token!
        }
        if lastDate != nil {
            profile["lastDate"] = Model.shared.dateFormatter.string(from: lastDate as! Date)
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
        token = profile["token"] as? String
        if let lat = profile["latitude"] as? Double {
            latitude = lat
        } else {
            latitude = 0
        }
        if let lon = profile["longitude"] as? Double {
            longitude = lon
        } else {
            longitude = 0
        }
        if let dateVal = profile["lastDate"] as? String {
            lastDate = Model.shared.dateFormatter.date(from: dateVal) as NSDate?
        }

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
