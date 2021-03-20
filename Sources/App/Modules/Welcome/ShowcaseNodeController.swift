//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 20.03.2021.
//

import Foundation
import Botter
import Vapor

class ShowcaseNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            name: "Showcase node",
            messagesGroup: [
                .init(text: "Тут описание бота в деталях.", keyboard: [[
                    try .init(text: "Перейти в главное меню", action: .callback, eventPayload: .push(.entryPoint(.welcome)))
                ]])
            ],
            entryPoint: .showcase,
            app: app
        )
    }
}
