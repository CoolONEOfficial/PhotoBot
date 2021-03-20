//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 20.03.2021.
//

import Foundation
import Botter
import Vapor

class WelcomeNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            name: "Welcome guest node",
            messagesGroup: [
                .init(text: "Привет, " + .replacing(by: .userFirstName) + "! Похоже ты тут впервые) Хочешь узнать что делает этот бот?", keyboard: [[
                    try .init(text: "Да", action: .callback, eventPayload: .push(.entryPoint(.showcase))),
                    try .init(text: "Нет", action: .callback, eventPayload: .push(.entryPoint(.welcome)))
                ]])
            ],
            entryPoint: .welcomeGuest, app: app
        )
    }
}
