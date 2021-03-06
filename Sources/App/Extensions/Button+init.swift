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

//static func create(text: String, action: Action, color: Vkontakter.Button.Color? = nil, eventPayload: EventPayload?, app: Application) -> Future<Self> {
//    guard let eventPayload = eventPayload else {
//        return app.eventLoopGroup.future(.init(text: text, action: action, color: color))
//    }
//    return EventPayloadModel(eventPayload).saveWithId(on: app.db).flatMapThrowing { id in
//        try Self.init(text: text, action: action, color: color, data: id)
//    }
