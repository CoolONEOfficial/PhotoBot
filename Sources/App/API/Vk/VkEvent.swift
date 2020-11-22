//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 22.11.2020.
//

import Foundation
import Vapor

struct VkEvent: Content {
    enum EventType: String, Content {
        case confirmation
        case message_new
    }
    var type: EventType
    
    struct Object: Content {
        struct Message: Content {
            let date: Int64
            let from_id: Int64
            let id: Int64
            let peer_id: Int64
            let text: String
            let conversation_message_id: Int64
            let important: Bool
            let random_id: Int64
        }

        let message: Message?
    }
    var object: Object?
}
