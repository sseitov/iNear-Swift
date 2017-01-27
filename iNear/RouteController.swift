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
    
    private var userMarker:GMSMarker?
    private var promptText:String = ""
    private var titleText:String = ""
    
    private var userLocation:CLLocationCoordinate2D?
    private var myLocation:CLLocationCoordinate2D?
    private var locationDate:Date?
    private var userTrack:GMSPolyline?
    private var startMarker:GMSMarker?
    private var finishMarker:GMSMarker?
    private var update:GMSCameraUpdate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackButton()
        navigationController?.navigationBar.tintColor = UIColor.white
        
        let myPoint = Model.shared.lastUserLocation(user: currentUser()!)
        myLocation = CLLocationCoordinate2D(latitude: myPoint!.latitude, longitude: myPoint!.longitude)
        
        let point = Model.shared.lastUserLocation(user: self.user!)
        locationDate = Model.shared.dateFormatter.date(from: point!.date!)
        userLocation = CLLocationCoordinate2D(latitude: point!.latitude, longitude: point!.longitude)
        
        promptText = "\(self.user!.shortName) was \(Model.shared.textDateFormatter.string(from: locationDate!))"
        titleText = "Get route to \(self.user!.shortName)..."
        setupTitle(self.titleText, promptText: self.promptText)
        
        map.camera = GMSCameraPosition.camera(withTarget: self.userLocation!, zoom: 6)
        map.isMyLocationEnabled = true
        userMarker = self.marker(forUser: self.user!)
        
        let points = Model.shared.userTrack(self.user!)
        if points != nil && points!.count > 1 {
            let path = GMSMutablePath()
            var bounds = GMSCoordinateBounds()
            for pt in points! {
                path.add(CLLocationCoordinate2D(latitude: pt.latitude, longitude: pt.longitude))
                bounds = bounds.includingCoordinate(CLLocationCoordinate2D(latitude: pt.latitude, longitude: pt.longitude))
            }
            self.userTrack = GMSPolyline(path: path)
            self.userTrack?.strokeColor = UIColor.traceColor()
            self.userTrack?.strokeWidth = 4
            let start = points!.first!
            self.startMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: start.latitude, longitude: start.longitude))
            self.startMarker?.icon = UIImage(named: "startPoint")
            let finish = points!.last!
            self.finishMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: finish.latitude, longitude: finish.longitude))
            self.finishMarker?.icon = UIImage(named: "finishPoint")
            
            let showTrackButton = UIBarButtonItem(title: "Show track", style: .plain, target: self, action: #selector(RouteController.showTrack))
            showTrackButton.tintColor = UIColor.white
            self.navigationItem.rightBarButtonItem = showTrackButton
            self.update = GMSCameraUpdate.fit(bounds, withPadding: 100)
        } else {
            self.update = GMSCameraUpdate.setTarget(CLLocationCoordinate2D(latitude: myLocation!.latitude, longitude: myLocation!.longitude), zoom: 12)
        }
        self.map.moveCamera(self.update!)
    }

    func marker(forUser:User) -> GMSMarker {
        let marker = GMSMarker(position: userLocation!)
        marker.icon = forUser.getImage().withSize(CGSize(width: 60, height: 60)).inCircle()
        if forUser.uid! != currentUser()!.uid! {
            marker.title = forUser.shortName
            marker.snippet = Model.shared.textDateFormatter.string(from: locationDate!)
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
        
        SVProgressHUD.show(withStatus: "Refresh...")
        GMSGeocoder().reverseGeocodeCoordinate(self.userMarker!.position, completionHandler: { response, error in
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
            self.createDirection(from: self.myLocation!, to: self.userLocation!, completion: { result in
                SVProgressHUD.dismiss()
                if result == -1 {
                    self.showMessage("Can not create route to \(self.user!.shortName)", messageType: .error)
                } else if result == 0 {
                    self.showMessage("You are in the same place.", messageType: .information)
                }
            })
        })
    }

    private func createDirection(from:CLLocationCoordinate2D, to:CLLocationCoordinate2D, completion: @escaping(Int) -> ()) {
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
    
    func showTrack() {
        userTrack!.map = self.map
        startMarker!.map = self.map
        finishMarker!.map = self.map
        let hideTrackButton = UIBarButtonItem(title: "Hide track", style: .plain, target: self, action: #selector(RouteController.hideTrack))
        hideTrackButton.tintColor = UIColor.white
        navigationItem.setRightBarButton(hideTrackButton, animated: true)
        map.moveCamera(update!)
    }
    
    func hideTrack() {
        userTrack!.map = nil
        startMarker!.map = nil
        finishMarker!.map = nil
        let showTrackButton = UIBarButtonItem(title: "Show track", style: .plain, target: self, action: #selector(RouteController.showTrack))
        showTrackButton.tintColor = UIColor.white
        navigationItem.setRightBarButton(showTrackButton, animated: true)
        map.moveCamera(update!)
    }
    
}
