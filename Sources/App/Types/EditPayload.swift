//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.01.2021.
//

import Foundation

struct EditPayload: Codable {
    enum `Type`: String, Codable {
        case edit_text
    }
    
    let type: Type
    let messageId: Int
}
