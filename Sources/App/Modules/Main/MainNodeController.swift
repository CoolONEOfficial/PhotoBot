//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 19.03.2021.
//

import Foundation
import Botter
import Vapor

class MainNodeController: NodeController {

    func create(app: Application) -> Future<Node> {
        Node.create(
            name: "Welcome node",
            messagesGroup: .welcome,
            entryPoint: .welcome, app: app
        )
    }

    func getSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol, group: SendMessageGroup) throws -> Future<[SendMessage]>? {
        guard case .welcome = group else { return nil }
        
        return context.app.eventLoopGroup.future([
            .init(text: "Добро пожаловать, " + .replacing(by: .userFirstName) + "! Выбери секцию чтобы в нее перейти.", keyboard: [
                [
                    try .init(text: "👧 Обо мне", action: .callback, eventPayload: .push(.entryPoint(.about))),
                    try .init(text: "🖼️ Мои работы", action: .callback, eventPayload: .push(.entryPoint(.portfolio))),
                ],
                [
                    try .init(text: "📷 Заказ фотосессии", action: .callback, eventPayload: .push(.entryPoint(.orderTypes))),
                    try .init(text: "🌟 Отзывы", action: .callback, eventPayload: .push(.entryPoint(.reviews))),
                ],
                [
                    try .init(text: "📆 Заказы", action: .callback, eventPayload: .push(.entryPoint(.orders))),
                ] + (context.user.isAdmin ? [
                    try .init(text: "Выгрузить фотку", action: .callback, eventPayload: .push(.entryPoint(.uploadPhoto))),
                ] : []),
            ])
        ])
    }
    
}
