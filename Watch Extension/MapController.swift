//
//  MapController.swift
//  iNear
//
//  Created by Сергей Сейтов on 12.12.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import WatchKit

class MapController: WKInterfaceController {

    @IBOutlet var map: WKInterfaceMap!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        if let params = context as? [String:Any], let user = params["user"] as? String, let positions = params["position"] as? [String:Any] {
            if let myPoint = positions["myPoint"] as? [String:Any], let userPoint = positions["userPoint"] as? [String:Any] {
                let lat1 = myPoint["latitude"] as! Double
                let lon1 = myPoint["longitude"] as! Double
                let coord1 = CLLocationCoordinate2D(latitude: lat1, longitude: lon1)
                let lat2 = userPoint["latitude"] as! Double
                let lon2 = userPoint["longitude"] as! Double
                let coord2 = CLLocationCoordinate2D(latitude: lat2, longitude: lon2)
                var region =  MKCoordinateRegionForMapRect(MKMapRect(coordinates: [coord1, coord2]))
                var latDelta = abs(lat1 - lat2)
                if latDelta > 1 {
                    latDelta = 1
                }
                if latDelta < 0.1 {
                    latDelta = 0.1
                }
                var lonDelta = abs(lon1 - lon2)
                if lonDelta > 1 {
                    lonDelta = 1
                }
                if lonDelta < 0.1 {
                    lonDelta = 0.1
                }
                let delta = latDelta > lonDelta ? latDelta : lonDelta
                region.span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
                map.setRegion(region)
                map.addAnnotation(coord1, with: .red)
                if let image = contactImage(uid: user) {
                    map.addAnnotation(coord2, with: image.withSize(CGSize(width: 20, height: 20)), centerOffset: CGPoint(x: 0, y: 0))
                } else {
                    map.addAnnotation(coord2, with: UIImage(named: "position"), centerOffset: CGPoint(x: 0, y: -13))
                }
            }
        }
    }

    func contactImage(uid:String) -> UIImage? {
        if let list = UserDefaults.standard.object(forKey: "contacts") as? [String:Any] {
            if let user = list[uid] as? [String:Any] {
                if let imageData = user["image"] as? Data {
                    return UIImage(data: imageData)
                }
            }
        }
        return nil
    }
}

extension MKMapRect {
    init(coordinates: [CLLocationCoordinate2D]) {
        self = coordinates.map({ MKMapPointForCoordinate($0) }).map({ MKMapRect(origin: $0, size: MKMapSize(width: 0, height: 0)) }).reduce(MKMapRectNull, MKMapRectUnion)
    }
}
