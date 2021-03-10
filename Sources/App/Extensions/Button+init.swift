//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 01.02.2021.
//

import Botter
import Vkontakter
import Vapor
import Foundation

extension Botter.Button {
    init(text: String, action: Action, color: Vkontakter.Button.Color? = nil, eventPayload: EventPayload?) throws {
        try self.init(text: text, action: action, color: color, data: eventPayload)
    }
}
