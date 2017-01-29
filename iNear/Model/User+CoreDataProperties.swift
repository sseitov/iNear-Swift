//
//  User+CoreDataProperties.swift
//  iNear
//
//  Created by Сергей Сейтов on 29.01.17.
//  Copyright © 2017 Сергей Сейтов. All rights reserved.
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User");
    }

    @NSManaged public var email: String?
    @NSManaged public var familyName: String?
    @NSManaged public var givenName: String?
    @NSManaged public var image: String?
    @NSManaged public var imageData: NSData?
    @NSManaged public var name: String?
    @NSManaged public var token: String?
    @NSManaged public var type: Int16
    @NSManaged public var uid: String?
    @NSManaged public var uploadedOnWatch: Bool
    @NSManaged public var lastTrack: String?
    @NSManaged public var contacts: NSSet?
    @NSManaged public var messages: Message?
    @NSManaged public var location: Coordinate?

}

// MARK: Generated accessors for contacts
extension User {

    @objc(addContactsObject:)
    @NSManaged public func addToContacts(_ value: Contact)

    @objc(removeContactsObject:)
    @NSManaged public func removeFromContacts(_ value: Contact)

    @objc(addContacts:)
    @NSManaged public func addToContacts(_ values: NSSet)

    @objc(removeContacts:)
    @NSManaged public func removeFromContacts(_ values: NSSet)

}
