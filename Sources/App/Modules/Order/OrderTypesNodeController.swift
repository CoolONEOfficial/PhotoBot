//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 20.03.2021.
//

import Foundation
import Botter
import Vapor

class OrderTypesNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            name: "Order types node",
            messagesGroup: [
                .init(text: "Выберите тип фотосессии:"),
                .init(text: "Love story", keyboard: [[
                    try .init(text: "Выбрать", action: .callback, eventPayload: .push(.entryPoint(.orderBuilder), payload: .orderBuilder(.init(type: .loveStory))))
                ]]),
                .init(text: "Контент сьемка", keyboard: [[
                    try .init(text: "Выбрать", action: .callback, eventPayload: .push(.entryPoint(.orderBuilder), payload: .orderBuilder(.init(type: .content))))
                ]]),
                .init(text: "Семейная фотосессия", keyboard: [[
                    try .init(text: "Выбрать", action: .callback, eventPayload: .push(.entryPoint(.orderBuilder), payload: .orderBuilder(.init(type: .family))))
                ]]),
            ],
            entryPoint: .orderTypes, app: app
        )
    }
}
