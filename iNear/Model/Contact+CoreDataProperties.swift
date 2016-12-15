//
//  Contact+CoreDataProperties.swift
//  iNear
//
//  Created by Сергей Сейтов on 15.12.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import Foundation
import CoreData


extension Contact {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Contact> {
        return NSFetchRequest<Contact>(entityName: "Contact");
    }

    @NSManaged public var uid: String?
    @NSManaged public var initiator: String?
    @NSManaged public var requester: String?
    @NSManaged public var status: Int16
    @NSManaged public var owner: User?

}
