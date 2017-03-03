//
//  SnapShotController.swift
//  iNear
//
//  Created by Сергей Сейтов on 03.03.17.
//  Copyright © 2017 Сергей Сейтов. All rights reserved.
//

import UIKit
import SVProgressHUD

class SnapShotController: UIViewController {

    @IBOutlet weak var trackImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitle("My track")
        setupBackButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SVProgressHUD.show(withStatus: "Create...")
        LocationManager.shared.trackShapshot(size: trackImage.frame.size, result: { image in
            SVProgressHUD.dismiss()
            self.trackImage.image = image
        })
    }
    

}
