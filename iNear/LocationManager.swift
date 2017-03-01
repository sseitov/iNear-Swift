//
//  LocationManager.swift
//  iNear
//
//  Created by Сергей Сейтов on 01.03.17.
//  Copyright © 2017 Сергей Сейтов. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import GoogleMaps

class LocationManager: NSObject {
    
    static let shared = LocationManager()
    
    let locationManager = CLLocationManager()
    var isRunning:Bool = false
    
    private override init() {
        super.init()
    }

    func register() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 10.0
            locationManager.headingFilter = 5.0
            if CLLocationManager.authorizationStatus() != .authorizedAlways {
                locationManager.requestAlwaysAuthorization()
            } else {
                locationManager.allowsBackgroundLocationUpdates = true
            }
        }
    }
    
    func start() -> Bool {
        if !isRunning && CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
            isRunning = true
        }
        return isRunning
    }
    
    func stop() {
        if isRunning {
            locationManager.stopUpdatingLocation()
            isRunning = false
        }
    }
    
    // MARK: - CoreData stack
    
    lazy var applicationDocumentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "LocationModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("LocationModel.sqlite")
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
        } catch {
            print("CoreData data error: \(error)")
        }
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                print("Saved data error: \(error)")
            }
        }
    }
    
    // MARK: - Location table
    
    func addCoordinate(_ coordinate:CLLocationCoordinate2D, at:Double) {
        let point = NSEntityDescription.insertNewObject(forEntityName: "Location", into: managedObjectContext) as! Location
        point.date = at
        point.latitude = coordinate.latitude
        point.longitude = coordinate.longitude
        saveContext()
    }

    func hasLocations() -> Bool {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        if let count = try? managedObjectContext.count(for: fetchRequest) {
            return count > 0
        } else {
            return false
        }
    }
    
    func myLocation() -> CLLocationCoordinate2D? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.fetchLimit = 1
        if let all = try? managedObjectContext.fetch(fetchRequest) as! [Location], let location = all.first {
            return CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        } else {
            return nil
        }
    }
    
    func myLastLocationDate() -> Date? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.fetchLimit = 1
        if let all = try? managedObjectContext.fetch(fetchRequest) as! [Location], let location = all.first {
            return Date(timeIntervalSince1970: location.date)
        } else {
            return nil
        }
    }
    
    func myTrack() -> GMSMutablePath? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let all = try? managedObjectContext.fetch(fetchRequest) as! [Location]
        if all != nil && all!.count > 1 {
            let path = GMSMutablePath()
            for pt in all! {
                path.add(CLLocationCoordinate2D(latitude: pt.latitude, longitude: pt.longitude))
            }
            return path
        } else {
            return nil
        }
    }
    
    func myTrackForLastDay() -> String? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -1, to: Date())
        fetchRequest.predicate = NSPredicate(format: "date >= %f", startDate!.timeIntervalSince1970)
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let all = try? managedObjectContext.fetch(fetchRequest) as! [Location]
        if all != nil && all!.count > 1 {
            let path = GMSMutablePath()
            for pt in all! {
                path.add(CLLocationCoordinate2D(latitude: pt.latitude, longitude: pt.longitude))
            }
            return path.encodedPath()
        } else {
            return nil
        }
    }
    
    func clearTrack() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        if var all = try? managedObjectContext.fetch(fetchRequest) as! [Location] {
            while all.count > 1 {
                let point = all.last!
                managedObjectContext.delete(point)
                all.removeLast()
            }
        }
    }
    
    func clearAll() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        if var all = try? managedObjectContext.fetch(fetchRequest) as! [Location] {
            while all.count > 0 {
                let point = all.last!
                managedObjectContext.delete(point)
                all.removeLast()
            }
        }
    }

}

extension LocationManager : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            if location.horizontalAccuracy <= 10.0 {
                addCoordinate(location.coordinate, at:NSDate().timeIntervalSince1970)
            }
        }
    }
}
