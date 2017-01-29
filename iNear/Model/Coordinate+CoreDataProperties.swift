//
//  Coordinate+CoreDataProperties.swift
//  iNear
//
//  Created by Сергей Сейтов on 29.01.17.
//  Copyright © 2017 Сергей Сейтов. All rights reserved.
//

import Foundation
import CoreData


extension Coordinate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Coordinate> {
        return NSFetchRequest<Coordinate>(entityName: "Coordinate");
    }

    @NSManaged public var date: Double
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var user: User?

}
