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
import MapKit

class LocationManager: NSObject {
    
    static let shared = LocationManager()
    
    let locationManager = CLLocationManager()
    let startMarker = UIImage(named: "startPoint")
    let finishMarker = UIImage(named: "finishPoint")
   
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0
        locationManager.headingFilter = 5.0
    }

    func register() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.allowsBackgroundLocationUpdates = true
            if CLLocationManager.authorizationStatus() != .authorizedAlways {
                locationManager.requestAlwaysAuthorization()
            }
        }
    }
    
    func start() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
            sharedDefaults.set(true, forKey: "trackerRunning")
            sharedDefaults.synchronize()
        }
    }
    
    func stop() {
        if isRunning() {
            locationManager.stopUpdatingLocation()
            sharedDefaults.set(false, forKey: "trackerRunning")
            sharedDefaults.synchronize()
        }
    }
    
    func isRunning() -> Bool {
        return sharedDefaults.bool(forKey: "trackerRunning")
    }
    
    // MARK: - CoreData stack
    
    lazy var sharedDefaults: UserDefaults = {
        return UserDefaults(suiteName: "group.com.vchannel.iNearby")!
    }()
    
    lazy var sharedDocumentsDirectory: URL = {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.vchannel.iNearby")!
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "LocationModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.sharedDocumentsDirectory.appendingPathComponent("LocationModel.sqlite")
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

    func myTrack(_ size:Int = 0) -> [Location]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        if size > 0 {
            fetchRequest.fetchLimit = size
        }
        return try? managedObjectContext.fetch(fetchRequest) as! [Location]
    }
    
    func myTrackForLastDay() -> [Location]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -1, to: Date())
        fetchRequest.predicate = NSPredicate(format: "date >= %f", startDate!.timeIntervalSince1970)
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        return try? managedObjectContext.fetch(fetchRequest) as! [Location]
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
            saveContext()
        }
    }
    
    func trackSize() -> Int {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        if let count = try? managedObjectContext.count(for: fetchRequest) {
            return count
        } else {
            return 0
        }
    }
    
    func locationShapshot(size:CGSize, result:@escaping (UIImage?) -> ()) {
        let center = myLocation()
        if center == nil {
            result(nil)
            return
        }
        
        let options = MKMapSnapshotOptions()
        options.mapType = .standard
        options.scale = 1.0
        options.size = size
        let span = MKCoordinateSpanMake(0.1, 0.1)
        options.region = MKCoordinateRegionMake(center!, span)

        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start(with: DispatchQueue.main, completionHandler: { snap, error in
            if error != nil {
                print(error!)
                result(nil)
                return
            }
            if let image = snap?.image {
                UIGraphicsBeginImageContext(image.size)
                image.draw(at: CGPoint())
                
                var startPt = snap!.point(for: center!)
                startPt = CGPoint(x: startPt.x - self.startMarker!.size.width/2.0, y: startPt.y - self.startMarker!.size.height/2.0)
                self.startMarker!.draw(at: startPt)
                
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                result(image)
            } else {
                result(nil)
            }
        })
    }
    
    func trackShapshot(size:CGSize, pointsCoint:Int, result:@escaping (UIImage?) -> ()) {
        let track = myTrack(pointsCoint)
        if track == nil {
            result(nil)
            return
        }
        
        var points:[CLLocationCoordinate2D] = []
        for i in 0..<track!.count {
            let loc = track![i]
            points.append(CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude))
        }
        
        let options = MKMapSnapshotOptions()
        let rect = MKMapRect(coordinates: points)
        let inset = -rect.size.width*0.1
        options.mapRect = MKMapRectInset(rect, inset, inset)
        options.mapType = .standard
        options.scale = 1.0
        options.size = size
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start(with: DispatchQueue.main, completionHandler: { snap, error in
            if error != nil {
                print(error!)
                result(nil)
                return
            }
            if let image = snap?.image {
                UIGraphicsBeginImageContext(image.size)
                image.draw(at: CGPoint())
                let context = UIGraphicsGetCurrentContext()
                context?.setLineWidth(4.0)
                context?.setStrokeColor(UIColor.traceColor().cgColor)
                context?.beginPath()
                
                var startPt:CGPoint = CGPoint()
                var drawPt:CGPoint = CGPoint()
                for i in 0..<points.count {
                    drawPt = snap!.point(for: points[i])
                    if i == 0 {
                        startPt = drawPt
                        context?.move(to: drawPt)
                    } else {
                        context?.addLine(to: drawPt)
                    }
                }
                
                startPt = CGPoint(x: startPt.x - self.startMarker!.size.width/2.0, y: startPt.y - self.startMarker!.size.height/2.0)
                self.startMarker!.draw(at: startPt)
                if points.count > 1 {
                    context?.strokePath()
                    drawPt = CGPoint(x: drawPt.x - self.finishMarker!.size.width/2.0, y: drawPt.y - self.finishMarker!.size.height/2.0)
                    self.finishMarker!.draw(at: startPt)
                    self.startMarker!.draw(at: drawPt)
                }
                                
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                result(image)
            } else {
                result(nil)
            }
        })
    }

}

extension LocationManager : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            if location.horizontalAccuracy <= 10.0 {
                addCoordinate(location.coordinate, at:NSDate().timeIntervalSince1970)
            }
        }
    }
}
