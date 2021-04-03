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
    
    func handleAction(_ action: NodeAction, _ message: Message, _ text: String, context: PhotoBotContextProtocol) throws -> EventLoopFuture<Result<Void, HandleActionError>>? {
        guard case .applyPromocode = action.type else { return nil }
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
            MessageFormatter.shared.format("Заказ успешно создан, в ближайшее время с Вами свяжется @" + .replacing(by: .admin), platform: platform, context: context)
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
                    func getMessage(_ platform: AnyPlatform) -> Future<String> {
                        MessageFormatter.shared.format(
                            [
                                "Новый заказ от @" + .replacing(by: .username) + " (" + .replacing(by: .orderId) + "):",
                                .replacing(by: .orderBlock),
                                .replacing(by: .priceBlock),
                            ].joined(separator: "\n"),
                            platform: platform, context: context
                        )
                    }
                    
                    var futures: [Future<[Message]>] = [
                        order.fetchWatchers(app: app).flatMap {
                            $0.map { watcher in
                                let platformIds = watcher.platformIds
                                
                                let platformId = platformIds.first(for: platform) ?? platformIds.first!
                                return getMessage(platformId.any).throwingFlatMap { text in
                                    try bot.sendMessage(.init(
                                        destination: platformId.sendDestination,
                                        text: text
                                    ), platform: platformId.any, context: context)
                                }
                            }.flatten(on: app.eventLoopGroup.next()).map { messages + $0.reduce([], +) }
                        }
                    ]
                    
//                    if let user = user, let id = user.platformIds.firstValue(platform: platform)?.id {
//                        futures.append(getMessage(platform).throwingFlatMap { text in
//                            try bot.sendMessage(.init(
//                                destination: .init(platform: platform, id: id),
//                                text: text
//                            ), platform: platform, context: context)
//                        })
//                    }
                    
                    return futures.flatten(on: app.eventLoopGroup.next()).map { $0.reduce([], +) }
                }
            }
        }.throwingFlatMap { messages in
            try user.popToMain(to: event, context: context).map { messages + $0 }
        }
    }
}
