//
//  MediaItems.swift
//  iNear
//
//  Created by Сергей Сейтов on 04.03.17.
//  Copyright © 2017 Сергей Сейтов. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class TrackMediaItem : JSQLocationMediaItem {
    
    var track:String?
    var cashedImageView:UIImageView?
    
    override func setLocation(_ location: CLLocation!, withCompletionHandler completion: JSQLocationMediaItemCompletionBlock!) {
        if location != nil {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 120))
            LocationManager.shared.trackShapshot(size: imageView.frame.size,
                                                 points: Model.shared.trackPoints(track!),
                                                 result: { image in
                imageView.image = image
                JSQMessagesMediaViewBubbleImageMasker.applyBubbleImageMask(toMediaView: imageView,
                                                                           isOutgoing: self.appliesMediaViewMaskAsOutgoing)
                self.cashedImageView = imageView
                completion()
            })
        }
    }
    
    override func mediaView() -> UIView! {
        return cashedImageView
    }
    
    override func mediaViewDisplaySize() -> CGSize {
        return CGSize(width: 200, height: 120)
    }
}

class Avatar : NSObject, JSQMessageAvatarImageDataSource {
    
    var userImage:UIImage?
    
    init(_ user:User) {
        super.init()
        self.userImage = user.getImage().inCircle()
    }
    
    func avatarImage() -> UIImage! {
        return userImage
    }
    
    func avatarHighlightedImage() -> UIImage! {
        return userImage
    }
    
    func avatarPlaceholderImage() -> UIImage! {
        return UIImage(named: "logo")?.inCircle()
    }
}
