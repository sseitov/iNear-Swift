//
//  TodayViewController.swift
//  Today
//
//  Created by Сергей Сейтов on 01.03.17.
//  Copyright © 2017 Сергей Сейтов. All rights reserved.
//

import UIKit
import NotificationCenter
import MapKit

class TodayViewController: UIViewController, NCWidgetProviding {
            
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var trashView: UIView!
    @IBOutlet weak var observeView: UIView!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var trackCounter: UILabel!
    @IBOutlet weak var mapView: UIImageView!
    @IBOutlet weak var progress: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        dateButton.setupBorder(UIColor.clear, radius: 15)
        mapView.setupBorder(UIColor.clear, radius: 10)
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        refresh()
    }
    
    func formattedDate() -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM HH:mm:ss"
        if let date = LocationManager.shared.myLastLocationDate() {
            return formatter.string(from: date).uppercased()
        } else {
            return nil
        }
    }
  
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .expanded {
            self.preferredContentSize = CGSize(width: maxSize.width, height: 430)
        } else {
            self.preferredContentSize = maxSize
        }
    }

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        refresh()
        completionHandler(NCUpdateResult.newData)
    }
    
    @IBAction func startTracker(_ sender: UIButton) {
        if LocationManager.shared.isRunning() {
            LocationManager.shared.stop()
            recordButton.setImage(UIImage(named: "location"), for: .normal)
        } else {
            LocationManager.shared.start()
            recordButton.setImage(UIImage(named: "stop"), for: .normal)
        }
    }
    
    @IBAction func openApp(_ sender: Any) {
        extensionContext?.open(URL(string: "iNearby://")!, completionHandler: nil)
    }
    
    @IBAction func refresh() {
        if let date = formattedDate() {
            dateButton.setTitle("LAST POINT: \(date)", for: .normal)
        } else {
            dateButton.setTitle("REFRESH STATUS", for: .normal)
        }
        let trackSize = LocationManager.shared.trackSize()
        if trackSize > 1 {
            trashView.isHidden = false
            trackCounter.text = "CLEAR \(trackSize)"
        } else {
            trashView.isHidden = true
        }
        observeView.isHidden = trashView.isHidden
        
        if LocationManager.shared.isRunning() {
            recordButton.setImage(UIImage(named: "stop"), for: .normal)
        } else {
            recordButton.setImage(UIImage(named: "location"), for: .normal)
        }

        if !progress.isAnimating && mapView.frame.height > 0 {
            self.mapView.image = nil
            progress.startAnimating()
            LocationManager.shared.trackShapshot(size: self.mapView.frame.size, pointsCoint: 20, result: { image in
                self.progress.stopAnimating()
                self.mapView.image = image
            })
        }
    }
    
    @IBAction func clearTracker(_ sender: Any) {
        LocationManager.shared.clearTrack()
        dateButton.setTitle("REFRESH STATUS", for: .normal)
        trackCounter.text = ""
        trashView.isHidden = (LocationManager.shared.trackSize() < 2)
        observeView.isHidden = trashView.isHidden
    }

}
