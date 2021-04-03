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
                .init(text: "Это - бот Насти Царевой. Тут ты сможешь посмотреть мое портфолио, отзывы, заказать сьемку и многое другое.", keyboard: [[
                    try .init(text: "🔥 Вперед", action: .callback, eventPayload: .push(.entryPoint(.welcome)))
                ]])
            ],
            entryPoint: .showcase,
            app: app
        )
    }
}
