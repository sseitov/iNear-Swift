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

    @IBOutlet weak var map: GMSMapView!
    var user:User?
    var userMarker:GMSMarker?
    var promptText:String = ""
    var titleText:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackButton()
        navigationController?.navigationBar.tintColor = UIColor.white
        promptText = "\(self.user!.shortName) was \(Model.shared.textDateFormatter.string(from: self.user!.lastDate as! Date))"
        titleText = "Get route to \(user!.shortName)..."
        setupTitle(titleText, promptText: promptText)
        
        map.camera = GMSCameraPosition.camera(withTarget: user!.location()!, zoom: 6)
        map.isMyLocationEnabled = false
        userMarker = marker(forUser: user!)
    }

    func marker(forUser:User) -> GMSMarker {
        let marker = GMSMarker(position: forUser.location()!)
        marker.icon = forUser.getImage().withSize(CGSize(width: 60, height: 60)).inCircle()
        if forUser.uid! != currentUser()!.uid! {
            marker.title = forUser.shortName
            marker.snippet = Model.shared.textDateFormatter.string(from: forUser.lastDate as! Date)
        }
        marker.map = map
        return marker
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if userMarker != nil {
            setupTitle(titleText, promptText: promptText)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let myMarker = marker(forUser: currentUser()!)
        
        let bounds = GMSCoordinateBounds(coordinate: myMarker.position, coordinate: userMarker!.position)
        let update = GMSCameraUpdate.fit(bounds, withPadding: 100)
        map.moveCamera(update)
        
        SVProgressHUD.show(withStatus: "Refresh...")
        GMSGeocoder().reverseGeocodeCoordinate(userMarker!.position, completionHandler: { response, error in
            if response != nil {
                if let address = response!.firstResult() {
                    var addressText = ""
                    if address.locality != nil {
                        addressText += address.locality!
                    }
                    if address.thoroughfare != nil {
                        if addressText.isEmpty {
                            addressText += address.thoroughfare!
                        } else {
                            addressText += ", \(address.thoroughfare!)"
                        }
                    }
                    if addressText.isEmpty {
                        addressText = "Unknown place"
                    }
                    self.titleText = addressText
                    self.setupTitle(self.titleText, promptText: self.promptText)
                }
            }
            self.createDirection(from: myMarker.position, to: self.userMarker!.position, completion: { result in
                SVProgressHUD.dismiss()
                if result == -1 {
                    self.showMessage("Can not create route to \(self.user!.shortName)", messageType: .error)
                } else if result == 0 {
                    self.showMessage("You are in the same place.", messageType: .information)
                }
            })
        })
    }
    
    func createDirection(from:CLLocationCoordinate2D, to:CLLocationCoordinate2D, completion: @escaping(Int) -> ()) {
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
                                if let path = GMSPath(fromEncodedPath: points) {
                                    if path.count() > 2 {
                                        let polyline = GMSPolyline(path: path)
                                        polyline.strokeColor = UIColor.color(28, 79, 130, 0.7)
                                        polyline.strokeWidth = 7
                                        polyline.map = self.map
                                        completion(1)
                                    } else {
                                        completion(0)
                                    }
                                } else {
                                    completion(-1)
                                }
                                return
                            }
                        }
                    }
                }
            }
            completion(-1)
        }, failure: { task, error in
            print("SEND PUSH ERROR: \(error)")
            completion(-1)
        })

    }
}
