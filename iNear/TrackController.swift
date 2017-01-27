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
    
    private var userTrack:GMSPolyline?
    private var startMarker:GMSMarker?
    private var finishMarker:GMSMarker?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitle("My Track")
        setupBackButton()
        
        let points = Model.shared.userTrack(currentUser()!)
        if points!.count > 1 {
            var bounds = GMSCoordinateBounds()
            let path = GMSMutablePath()
            for pt in points! {
                bounds = bounds.includingCoordinate(CLLocationCoordinate2D(latitude: pt.latitude, longitude: pt.longitude))
                path.add(CLLocationCoordinate2D(latitude: pt.latitude, longitude: pt.longitude))
            }
            userTrack = GMSPolyline(path: path)
            userTrack?.strokeColor = UIColor.traceColor()
            userTrack?.strokeWidth = 4
            userTrack?.map = map
            let start = points!.first!
            startMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: start.latitude, longitude: start.longitude))
            startMarker?.icon = UIImage(named: "startPoint")
            startMarker?.map = map
            let finish = points!.last!
            finishMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: finish.latitude, longitude: finish.longitude))
            finishMarker?.icon = UIImage(named: "finishPoint")
            finishMarker?.map = map

            let update = GMSCameraUpdate.fit(bounds, withPadding: 100)
            map.moveCamera(update)
        } else {
            if let pt = Model.shared.lastUserLocation(user: currentUser()!) {
                let update = GMSCameraUpdate.setTarget(CLLocationCoordinate2D(latitude: pt.latitude, longitude: pt.longitude), zoom: 12)
                map.moveCamera(update)
            }
        }

    }
    
    @IBAction func clearTrack(_ sender: Any) {
        SVProgressHUD.show(withStatus: "Clear...")
        Model.shared.clearTrack {
            SVProgressHUD.dismiss()
            _ = self.navigationController?.popViewController(animated: true)
        }
    }

}
