//
//  TrackController.swift
//  iNear
//
//  Created by Сергей Сейтов on 27.01.17.
//  Copyright © 2017 Сергей Сейтов. All rights reserved.
//

import UIKit
import GoogleMaps
import SVProgressHUD

class TrackController: UIViewController {

    @IBOutlet weak var map: GMSMapView!
    
    var user:User?
    var fromRoot = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if user == currentUser() {
            setupTitle("My Track")
        } else {
            setupTitle("\(user!.shortName) track for last day")
        }
        setupBackButton()
        
        var path:GMSPath?
        if user == currentUser() {
            let all = LocationManager.shared.myTrack()
            let mutablePath = GMSMutablePath()
            for pt in all! {
                mutablePath.add(CLLocationCoordinate2D(latitude: pt.latitude, longitude: pt.longitude))
            }
            path = mutablePath
        } else {
            path = GMSPath(fromEncodedPath: user!.lastTrack!)
        }
        
        let userTrack = GMSPolyline(path: path)
        userTrack.strokeColor = UIColor.traceColor()
        userTrack.strokeWidth = 4
        userTrack.map = map
        if let start = path?.coordinate(at: 0) {
            let startMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: start.latitude, longitude: start.longitude))
            startMarker.icon = UIImage(named: "startPoint")
            startMarker.map = map
        }
        if let finish = path?.coordinate(at: path!.count() - 1) {
            let finishMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: finish.latitude, longitude: finish.longitude))
            finishMarker.icon = UIImage(named: "finishPoint")
            finishMarker.map = map
        }
        
        var bounds = GMSCoordinateBounds()
        for i in 0..<path!.count() {
            if let pt = path?.coordinate(at: i) {
                bounds = bounds.includingCoordinate(CLLocationCoordinate2D(latitude: pt.latitude, longitude: pt.longitude))
            }
        }
        let update = GMSCameraUpdate.fit(bounds, withPadding: 100)
        map.moveCamera(update)
    }
    
    override func goBack() {
        if fromRoot {
            dismiss(animated: true, completion: nil)
        } else {
            super.goBack()
        }
    }

}
