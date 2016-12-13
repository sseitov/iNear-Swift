//
//  RouteController.swift
//  iNear
//
//  Created by Сергей Сейтов on 13.12.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import UIKit
import GoogleMaps
import SVProgressHUD
import AFNetworking

class RouteController: UIViewController {

    var user:User?
    var mapView:GMSMapView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackButton()
        setupTitle("Route to \(user!.shortName)")
        
        let camera = GMSCameraPosition.camera(withTarget: user!.location(), zoom: 6)
        mapView = GMSMapView.map(withFrame: CGRect(), camera: camera)
        mapView!.isMyLocationEnabled = false
        self.view = mapView!
    }

    func marker(forUser:User) -> GMSMarker {
        let marker = GMSMarker(position: forUser.location())
        marker.icon = forUser.getImage().withSize(CGSize(width: 60, height: 60)).inCircle()
        if forUser.uid! != Model.shared.currentUser()!.uid! {
            marker.title = forUser.shortName
            marker.snippet = Model.shared.textDateFormatter.string(from: forUser.lastDate as! Date)
        }
        return marker
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let myMarker = marker(forUser: Model.shared.currentUser()!)
        myMarker.map = mapView
        let peer = marker(forUser: user!)
        peer.map = mapView
        
        let bounds = GMSCoordinateBounds(coordinate: myMarker.position, coordinate: peer.position)
        let update = GMSCameraUpdate.fit(bounds, withPadding: 100)
        mapView?.moveCamera(update)
        
        SVProgressHUD.show(withStatus: "Refresh...")
        GMSGeocoder().reverseGeocodeCoordinate(peer.position, completionHandler: { response, error in
            if response != nil {
                if let address = response!.firstResult() {
                    print(address) //.thoroughfare)
                }
            }
            self.createDirection(from: myMarker.position, to: peer.position, completion: { success in
                SVProgressHUD.dismiss()
                if !success {
                    self.showMessage("Can not create route to \(self.user!.shortName)", messageType: .error)
                }
            })
        })
    }
    
    func createDirection(from:CLLocationCoordinate2D, to:CLLocationCoordinate2D, completion: @escaping(Bool) -> ()) {
        let urlStr = String(format: "https://maps.googleapis.com/maps/api/directions/json?origin=%f,%f&destination=%f,%f&sensor=true", from.latitude, from.longitude, to.latitude, to.longitude)
        let manager = AFHTTPSessionManager()
        manager.requestSerializer = AFHTTPRequestSerializer()
        manager.responseSerializer = AFJSONResponseSerializer()
        manager.get(urlStr, parameters: nil, progress: nil, success: { task, response in
            if let json = response as? [String:Any] {
                if let routes = json["routes"] as? [Any] {
                    if let route = routes.first as? [String:Any] {
                        if let line = route["overview_polyline"] as? [String:Any] {
                            if let points = line["points"] as? String {
                                let path = GMSPath(fromEncodedPath: points)
                                let polyline = GMSPolyline(path: path)
                                polyline.strokeColor = UIColor.color(28, 79, 130, 0.7)
                                polyline.strokeWidth = 7
                                polyline.map = self.mapView
                                completion(true)
                                return
                            }
                        }
                    }
                }
            }
            completion(false)
        }, failure: { task, error in
            print("SEND PUSH ERROR: \(error)")
            completion(false)
        })

    }
}
