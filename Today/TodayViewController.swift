//
//  TodayViewController.swift
//  Today
//
//  Created by Сергей Сейтов on 01.03.17.
//  Copyright © 2017 Сергей Сейтов. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
            
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var trashButton: UIButton!
    @IBOutlet weak var observeButton: UIButton!
    @IBOutlet weak var dateView: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refresh()
    }
    
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM HH:mm:ss"
        if let date = LocationManager.shared.myLastLocationDate() {
            return formatter.string(from: date).uppercased()
        } else {
            return ""
        }
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        refresh()
        completionHandler(NCUpdateResult.newData)
    }
    
    @IBAction func startTracker(_ sender: UIButton) {
        var started = LocationManager.shared.isRunning
        if started {
            LocationManager.shared.stop()
            started = false
        } else {
            started = LocationManager.shared.start()
        }
        if started {
            recordButton.setImage(UIImage(named: "stop"), for: .normal)
        } else {
            recordButton.setImage(UIImage(named: "location"), for: .normal)
        }
    }
    
    @IBAction func openApp(_ sender: Any) {
        extensionContext?.open(URL(string: "iNearby://")!, completionHandler: nil)
    }
    
    @IBAction func refresh() {
        if LocationManager.shared.hasLocations() {
            dateView.text = formattedDate()
            trashButton.isHidden = false
            observeButton.isHidden = false
        } else {
            dateView.text = ""
            trashButton.isHidden = true
            observeButton.isHidden = true
        }
        if LocationManager.shared.isRunning {
            recordButton.setImage(UIImage(named: "stop"), for: .normal)
        } else {
            recordButton.setImage(UIImage(named: "location"), for: .normal)
        }
    }
    
    @IBAction func clearTracker(_ sender: Any) {
        LocationManager.shared.clearAll()
        dateView.text = ""
        trashButton.isHidden = !LocationManager.shared.hasLocations()
        observeButton.isHidden = trashButton.isHidden
    }
}
