//
//  User+CoreDataProperties.swift
//  iNear
//
//  Created by Сергей Сейтов on 01.12.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User");
    }

    @NSManaged public var email: String?
    @NSManaged public var imageData: NSData?
    @NSManaged public var nickName: String?
    @NSManaged public var uid: String?
    @NSManaged public var imageURL: String?

}
