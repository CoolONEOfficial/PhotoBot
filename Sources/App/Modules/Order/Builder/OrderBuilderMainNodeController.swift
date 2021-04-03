//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 20.03.2021.
//

import Foundation
import Botter
import Vapor

class OrderBuilderMainNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            name: "Order builder main node",
            messagesGroup: .orderBuilder,
            entryPoint: .orderBuilder, app: app
        )
    }
    
    func getSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol, group: SendMessageGroup) throws -> EventLoopFuture<[SendMessage]>? {
        guard case .orderBuilder = group else { return nil }
        
        let app = context.app
        
        guard case let .orderBuilder(state) = payload, let type = state.type else {
            return app.eventLoopGroup.future(error: SendMessageGroupError.invalidPayload)
        }
        
        var keyboard: Keyboard = [[
            try .init(text: "Студия", action: .callback, eventPayload: .push(.entryPoint(.orderBuilderStudio))),
            try .init(text: "Дата", action: .callback, eventPayload: .push(.entryPoint(.orderBuilderDate)))
        ]]

        switch type {
        case .loveStory, .family:
            keyboard.buttons[0].insert(contentsOf: [
                try .init(text: "Стилист", action: .callback, eventPayload: .push(.entryPoint(.orderBuilderStylist))),
                try .init(text: "Визажист", action: .callback, eventPayload: .push(.entryPoint(.orderBuilderMakeuper))),
            ], at: 0)
        case .content: break
        }
        
        if state.isValid {
            keyboard.buttons.safeAppend([
                try .init(text: "👌 К завершению", action: .callback, eventPayload: .pushCheckout(state: state))
            ])
        }
        
        return app.eventLoopGroup.future([ .init(
            text: [
                "Ваш заказ:",
                .replacing(by: .orderBlock),
                "Сумма: " + .replacing(by: .price)
            ].joined(separator: "\n"),
            keyboard: keyboard
        ) ])
    }
    
    func handleEventPayload(_ event: MessageEvent, _ eventPayload: EventPayload, _ replyText: inout String, context: PhotoBotContextProtocol) throws -> Future<[Botter.Message]>? {
        guard case let .pushCheckout(state) = eventPayload else { return nil }
        let (app, user) = (context.app, context.user)

        replyText = "Move"

        return PromotionModel.query(on: app.db).filter(\.$autoApply, .equal, true).all().flatMap { promotions -> Future<[Message]> in
            promotions.map { promo in
                promo.condition.check(state: state, context: context).map { (check: $0, promo: promo) }
            }
            .flatten(on: app.eventLoopGroup.next())
            .flatMap { promotions -> Future<[Message]> in
                let promotions = promotions.filter(\.check).map(\.promo)
                return user.push(.entryPoint(.orderCheckout), payload: .checkout(.init(order: state, promotions: promotions)), to: event, saveMove: true, context: context)
            }
        }
    }
}
