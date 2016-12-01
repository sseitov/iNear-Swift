//
//  ContactCell.swift
//  iNear
//
//  Created by Сергей Сейтов on 01.12.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import UIKit

class ContactCell: UITableViewCell {

    @IBOutlet weak var contactView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!

    var user:User? {
        didSet {
            if user!.nickName != nil {
                nameLabel.text = user!.nickName!
            } else {
                nameLabel.text = user!.email!
            }
            if user!.imageData != nil {
                contactView.image = UIImage(data: user!.imageData as! Data)
            } else {
                contactView.image = UIImage(named: "logo")
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contactView.setupCircle()
        nameLabel.setupBorder(UIColor.white, radius: 20)
    }

}
