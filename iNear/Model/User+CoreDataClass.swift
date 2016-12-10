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
        if token != nil {
            profile["token"] = token!
        }
        return profile
    }
    
    func setUserData(_ profile:[String : Any]) {
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
        token = profile["token"] as? String
        Model.shared.saveContext()
    }
    
    func getImage(_ result: @escaping(UIImage) -> ()) {
        if self.image != nil {
            SDImageCache.shared().queryDiskCache(forKey: self.image!, done: { webImage, cacheType in
                if webImage == nil {
                    SDWebImageManager.shared().downloadImage(with: self.imageURL!, options: SDWebImageOptions(rawValue:0), progress: {_, _ in
                    }, completed: { newImage, error, _, _, _ in
                        if newImage != nil {
                            result(newImage!)
                        } else {
                            result(UIImage(named:"unknown_user")!)
                        }
                    })
                } else {
                    result(webImage!)
                }
            })
        } else {
            result(UIImage(named:"unknown_user")!)
        }
    }

}
