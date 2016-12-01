//
//  ChatController.swift
//  iNear
//
//  Created by Сергей Сейтов on 01.12.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import UIKit
import Firebase
import JSQMessagesViewController

class ChatController: JSQMessagesViewController {

    var user:User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if user != nil {
            let name = user!.nickName != nil ? user!.nickName! : user!.email!
            setupTitle(name)
            self.senderDisplayName = name
            
            collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 36, height: 36)
            collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 36, height: 36)
            
            inputToolbar.contentView.rightBarButtonItem.titleLabel!.font = UIFont(name: "HelveticaNeue-CondensedBold", size: 15)
            inputToolbar.contentView.textView.font = UIFont(name: "HelveticaNeue-CondensedBold", size: 15)
        } else {
            self.senderDisplayName = ""
            inputToolbar.isHidden = true
        }
        self.senderId = FIRAuth.auth()!.currentUser!.uid
        if IS_PAD() {
            navigationItem.leftBarButtonItem = nil
        } else {
            setupBackButton()
        }
    }
}
