//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 23.11.2020.
//

import Foundation
import Vapor

struct VkMessage: Content, BotMessage {
    let date: Int64
    let from_id: Int64
    let id: Int64
    let peer_id: Int64
    let text: String?
    let conversation_message_id: Int64
    let important: Bool
    let random_id: Int64
}
