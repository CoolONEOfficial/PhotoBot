//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 16.03.2021.
//

import Foundation
import Botter
import Vkontakter

extension Botter.Button {
    init(text: String, action: NodeAction, color: Vkontakter.Button.Color? = nil, payload: String? = nil) throws {
        try self.init(text: text, action: .callback, color: color, data: action)
    }
}
