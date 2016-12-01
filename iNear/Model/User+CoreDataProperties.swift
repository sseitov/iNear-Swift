//
//  User+CoreDataProperties.swift
//  iNear
//
//  Created by Сергей Сейтов on 29.11.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User");
    }

    @NSManaged public var email: String?
    @NSManaged public var image: NSData?
    @NSManaged public var nickName: String?
    @NSManaged public var uid: String?

}
