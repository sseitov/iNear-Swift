//
//  ContactCell.swift
//  iNear
//
//  Created by Сергей Сейтов on 01.12.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import UIKit
import SDWebImage

class ContactCell: UITableViewCell {

    @IBOutlet weak var contactView: UIImageView!
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var nameLabel: UILabel!

    var user:User? {
        didSet {
            if user!.name != nil {
                nameLabel.text = user!.name
            } else {
                nameLabel.text = user!.email
            }
            contactView.image = user!.getImage()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contactView.setupCircle()
        background.setupBorder(UIColor.clear, radius: 35)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        nameLabel.textColor = selected ? UIColor.black : UIColor.white
    }

}
