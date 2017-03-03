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
        
        if let points = context as? [Any] {
            var coords:[CLLocationCoordinate2D] = []
            for i in 0..<points.count {
                if let pt = points[i] as? [String:Any],
                    let lat = pt["latitude"] as? Double,
                    let lon = pt["longitude"] as? Double {
                    
                    coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
                }
            }
            map.setVisibleMapRect(MKMapRect(coordinates: coords))
            for coord in coords {
                map.addAnnotation(coord, with: .green)
            }
        }
    }
    
    deinit {
        map.removeAllAnnotations()
    }
}

extension MKMapRect {
    init(coordinates: [CLLocationCoordinate2D]) {
        self = coordinates.map({ MKMapPointForCoordinate($0) }).map({ MKMapRect(origin: $0, size: MKMapSize(width: 0, height: 0)) }).reduce(MKMapRectNull, MKMapRectUnion)
    }
}
