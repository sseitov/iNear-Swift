//
//  UIViewControllerExtensions.swift
//  cryptoBox (MilCryptor Secure Platform)
//
//  Created by Denys Borysiuk on 19.07.16.
//  Copyright © 2016 ArchiSec Solutions, Ltd. All rights reserved.//
//

import UIKit

enum MessageType {
    case error, success, information
}

extension UIViewController {
    
    func setupTitle(_ text:String) {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        label.textAlignment = .center
        label.font = UIFont(name: "HelveticaNeue-CondensedBold", size: 15)
        label.text = text
        label.textColor = UIColor.white
        navigationItem.titleView = label
    }
    
    func setupBackButton() {
        navigationItem.leftBarButtonItem?.target = self
        navigationItem.leftBarButtonItem?.action = #selector(UIViewController.goBack)
    }
    
    func goBack() {
         _ = self.navigationController!.popViewController(animated: true)
    }
    
    // MARK: - alerts
    
    func showMessage(_ error:String, messageType:MessageType, messageHandler: (() -> ())? = nil) {
        var title:String = ""
        switch messageType {
        case .success:
            title = "Success"
        case .information:
            title = "Information"
        default:
            title = "Error"
        }
        let alert = LGAlertView.decoratedAlert(withTitle:title, message: error, cancelButtonTitle: "OK", cancelButtonBlock: { alert in
            if messageHandler != nil {
                messageHandler!()
            }
        })
        alert!.titleLabel.textColor = messageType == .error ? UIColor.errorColor() : UIColor.mainColor()
        alert?.show()
    }

}
