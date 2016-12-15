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
    @IBOutlet var zoomSlider: WKInterfaceSlider!
    
    var location:CLLocationCoordinate2D?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        zoomSlider.setValue(10)
        if let position = context as? [String:Any] {
            if let lat = position["latitude"] as? Double, let lon = position["longitude"] as? Double {
//                location = CLLocationCoordinate2D(latitude: 55.819349, longitude: 37.510184)
                location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let span = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
                let region = MKCoordinateRegion(center: location!, span: span)
                map.setRegion(region)
                map.addAnnotation(location!, with: .red)
            }
        }
    }
    
    @IBAction func zoom(_ value: Float) {
        if location != nil {
            let span = MKCoordinateSpan(latitudeDelta: Double(value/10.0), longitudeDelta: Double(value/10.0))
            let region = MKCoordinateRegion(center: location!, span: span)
            map.setRegion(region)
            map.addAnnotation(location!, with: .red)
        }
    }
}
