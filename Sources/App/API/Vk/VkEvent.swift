//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 22.11.2020.
//

import Foundation
import Vapor

struct VkEvent: Content {
//    enum `Type`: String, Content {
//        case confirmation
//        case message_new
//    }
    var type: String?
    
    struct Object: Content {
        let message: VkMessage?
    }
    var object: Object?
}
