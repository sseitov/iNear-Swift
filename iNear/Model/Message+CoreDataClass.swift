//
//  Message+CoreDataClass.swift
//  iNear
//
//  Created by Сергей Сейтов on 10.12.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import Foundation
import CoreData


public class Message: NSManagedObject {

    
    func getData() -> [String:Any] {
        var data:[String:Any] = ["to" : to!, "from" : from!, "text" : text!]
        data["date"] = Model.shared.dateFormatter.string(from: date as! Date)
        return data
    }
    
    func setData(_ data:[String:Any], new:Bool, completion:@escaping () -> ()) {
        from = data["from"] as? String
        to = data["to"] as? String
        text = data["text"] as? String
        imageURL = data["image"] as? String
        isNew = new
        if let dateVal = data["date"] as? String {
            date = Model.shared.dateFormatter.date(from: dateVal) as NSDate?
        }
        if imageURL != nil {
            let ref = Model.shared.storageRef.child(imageURL!)
            ref.data(withMaxSize: INT64_MAX, completion: { data, error in
                self.imageData = data as NSData?
                Model.shared.saveContext()
                completion()
            })
        } else {
            Model.shared.saveContext()
            completion()
        }
    }
}
