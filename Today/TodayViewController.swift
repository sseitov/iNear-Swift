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

    override func viewDidLoad() {
        super.viewDidLoad()
        dateButton.setupBorder(UIColor.clear, radius: 15)
        self.extensionContext?.widgetLargestAvailableDisplayMode = .compact
    }
    
    func formattedDate(_ date:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM HH:mm:ss"
        return formatter.string(from: date).uppercased()
    }

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        self.refresh()
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
        if let date = LocationManager.shared.myLastLocationDate() {
            dateButton.setTitle("LAST POINT: \(formattedDate(date))", for: .normal)
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
    }
    
    @IBAction func clearTracker(_ sender: Any) {
        LocationManager.shared.clearTrack()
        dateButton.setTitle("REFRESH STATUS", for: .normal)
        trackCounter.text = ""
        trashView.isHidden = (LocationManager.shared.trackSize() < 2)
        observeView.isHidden = trashView.isHidden
    }

}
