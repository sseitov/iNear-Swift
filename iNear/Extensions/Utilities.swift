//
//  Utilities.swift
//  iNear
//
//  Created by Сергей Сейтов on 18.11.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import Foundation

func generateUDID() -> String {
    return UUID().uuidString
}

func iNearError(_ text:String) -> NSError {
    return NSError(domain: "iNear", code: -1, userInfo: [NSLocalizedDescriptionKey:text])
}

func IS_PAD() -> Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
}

func WAIT(_ condition:NSCondition) {
    condition.lock()
    condition.wait()
    condition.unlock()
}

func SIGNAL(_ condition:NSCondition) {
    condition.lock()
    condition.signal()
    condition.unlock()
}
