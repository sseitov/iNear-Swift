//
//  TrackPoint+CoreDataProperties.swift
//  iNear
//
//  Created by Сергей Сейтов on 27.01.17.
//  Copyright © 2017 Сергей Сейтов. All rights reserved.
//

import Foundation
import CoreData


extension TrackPoint {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TrackPoint> {
        return NSFetchRequest<TrackPoint>(entityName: "TrackPoint");
    }

    @NSManaged public var date: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var user: User?

}
