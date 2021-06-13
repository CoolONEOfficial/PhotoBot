//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 20.03.2021.
//

import Foundation
import Botter
import Vapor

class OrderCheckoutNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            name: "Order checkout node",
            messagesGroup: .orderCheckout,
            entryPoint: .orderCheckout, action: .init(.applyPromocode), app: app
        )
    }
    
    func getSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol, group: SendMessageGroup) throws -> EventLoopFuture<[SendMessage]>? {
        guard case .orderCheckout = group else { return nil }
        
        let app = context.app

        return app.eventLoopGroup.future([ .init(
            text: [
                "Оформление заказа",
                .replacing(by: .orderBlock),
                .replacing(by: .priceBlock),
                .replacing(by: .promoBlock),
            ].joined(separator: "\n"),
            keyboard: [[
                try .init(text: "✅ Отправить", action: .callback, eventPayload: .createOrder)
            ]]
        ) ])
    }
    
    func handleAction(_ action: NodeAction, _ message: Message, context: PhotoBotContextProtocol) throws -> EventLoopFuture<Result<Void, HandleActionError>>? {
        guard case .applyPromocode = action.type, let text = message.text else { return nil }
        let (app, user) = (context.app, context.user)
        
        guard case var .checkout(checkoutState) = user.nodePayload else { throw HandleActionError.nodePayloadInvalid }
        
        return Promotion.find(promocode: text, app: app).flatMap { promotion in
            guard let promotion = promotion else { return app.eventLoopGroup.future(.failure(.promoNotFound)) }
            
            return promotion.condition.check(state: checkoutState.order, context: context).flatMap { check in
                guard check else { return app.eventLoopGroup.future(.failure(.promoCondition)) }

                return checkoutState.promotions.map { Promotion.find($0.id, app: app) }.flatten(on: app.eventLoopGroup.next()).throwingFlatMap { promotions in
                    
                    for promo in promotions.compactMap({ $0 }) where !promo.autoApply {
                        if let promoId = promo.id {
                            if let index = checkoutState.promotions.compactMap(\.id).firstIndex(of: promoId) {
                                checkoutState.promotions.remove(at: index)
                            }
                        }
                    }
                    
                    return try promotion.toTwin(app: app).flatMap { promotionModel in
                        checkoutState.promotions.append(promotionModel)
                        
                        return user.push(.entryPoint(.orderCheckout), payload: .checkout(checkoutState), to: message, context: context).map { _ in .success }
                    }
                }
                
                
            }
        }
    }
    
    func handleEventPayload(_ event: MessageEvent, _ eventPayload: EventPayload, _ replyText: inout String, context: PhotoBotContextProtocol) throws -> Future<[Botter.Message]>? {
        guard case .createOrder = eventPayload else { return nil }
        
        let (app, user, bot) = (context.app, context.user, context.bot)

        replyText = "Move"
        
        guard case let .checkout(checkoutState) = user.nodePayload, let userId = user.id else { throw HandleActionError.nodePayloadInvalid }
        
        let platform = event.platform.any
        
        return try OrderModel.create(userId: userId, checkoutState: checkoutState, app: app).flatMap { order in
            MessageFormatter.shared.format("Заказ успешно создан! После подтверждения заказа мы уведомим вас о готовности. По всем вопросам - к @" + .replacing(by: .admin), platform: platform, context: context)
            .throwingFlatMap { message in
                try event.replyMessage(.init(text: message), context: context)
            }.map { ($0, order) }
        }.flatMap { (messages, order) in
            CheckoutState.create(from: order, app: app).throwingFlatMap { orderState in
                context.user.nodePayload = .checkout(orderState)
                return try User.find(
                    destination: .username(Application.adminNickname(for: platform)),
                    platform: platform,
                    app: app
                ).flatMap { user in
                    
                    let futures: [Future<[Message]>] = [
                        order.fetchWatchers(app: app).throwingFlatMap {
                            try $0.map { watcher in
                                try watcher.getPlatformUser(app: app)
                                    .optionalThrowingFlatMap { try $0.toTwin(app: app) }
                                    .throwingFlatMap { user in
                                        guard let user = user, let lastDestination = user.lastDestination else { return app.eventLoopGroup.future([]) }
                                        return user.push(
                                            .entryPoint(.orderAgreement),
                                            payload: .orderAgreement(orderId: try order.requireID()),
                                            to: lastDestination, context: context
                                        )
                                    }
                            }.flatten(on: app.eventLoopGroup.next())
                            .map { messages + $0.reduce([], +) }
                        }
                    ]
                    
                    return futures.flatten(on: app.eventLoopGroup.next()).map { $0.reduce([], +) }
                }
            }
        }.throwingFlatMap { messages in
            try user.popToMain(to: event, context: context).map { messages + $0 }
        }
    }
}
