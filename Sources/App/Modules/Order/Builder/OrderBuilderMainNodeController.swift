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
                let promotions = promotions.filter(\.check).compactMap(\.promo.id)
                return user.push(.entryPoint(.orderCheckout), payload: .checkout(.init(order: state, promotions: promotions)), to: event, saveMove: true, context: context)
            }
        }
    }
}
