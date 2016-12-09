//
//  User+CoreDataProperties.swift
//  iNear
//
//  Created by Сергей Сейтов on 09.12.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User");
    }

    @NSManaged public var uid: String?
    @NSManaged public var name: String?
    @NSManaged public var image: String?
    @NSManaged public var email: String?
    @NSManaged public var token: String?
    @NSManaged public var givenName: String?
    @NSManaged public var familyName: String?
    @NSManaged public var type: Int16

}
