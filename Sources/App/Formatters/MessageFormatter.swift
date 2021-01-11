//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.01.2021.
//

import Foundation

class MessageFormatter {
    static let shared = MessageFormatter()
    
    func format(_ string: String, user: User) -> String {
        string.replacingOccurrences(of: "$USER", with: user.name ?? "<nope>")
    }
}
