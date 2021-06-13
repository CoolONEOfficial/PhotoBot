//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 06.06.2021.
//

import Foundation
import Botter
import Vapor

class OrderReplacementNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            name: "Order replacement node",
            messagesGroup: .orderReplacement,
            entryPoint: .orderReplacement, app: app
        )
    }
    
    func getSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol, group: SendMessageGroup) throws -> EventLoopFuture<[SendMessage]>? {
        guard case .orderReplacement = group else { return nil }
        
        let (app, user) = (context.app, context.user)
        
        switch payload {
        case let .orderReplacement(orderId, type):
            return PhotographerModel.query(on: app.db).first().optionalThrowingFlatMap { try $0.toTwin(app: app) }
                .flatMapThrowing { photographer in
                [
                    .init(text: "Один из работников, похоже, не сможет участвовать в заказе. Хочешь найти замену или отменить заказ?", keyboard: [[
                        try .init(text: "Отменить", action: .callback, eventPayload: .handleOrderReplacement(false)),
                        try .init(text: "Найти", action: .callback, eventPayload: .handleOrderReplacement(true)),
                    ]]),
                ]
            }
            
        case let .orderBuilder(state):

            guard case let .orderReplacement(orderId, _) = user.history.last?.nodePayload else {
                return app.eventLoopGroup.future(error: SendMessageGroupError.invalidPayload)
            }
            
            var future: EventLoopFuture<String?>
            
            if let makeuperId = state.makeuperId {
                future = Makeuper.find(makeuperId, app: app).map { $0?.name }
            } else if let stylistId = state.stylistId {
                future = Stylist.find(stylistId, app: app).map { $0?.name }
            } else if let photographId = state.photographerId {
                future = Photographer.find(photographId, app: app).map { $0?.name }
            } else if let studioId = state.studioId {
                future = Studio.find(studioId, app: app).map { $0?.name }
            } else {
                return app.eventLoopGroup.future(error: SendMessageGroupError.invalidPayload)
            }

            return future.unwrap(orError: SendMessageGroupError.invalidPayload).flatMapThrowing {
                [
                    SendMessage(text: "Подтвердить замену на \($0)", keyboard: [[
                        try .init(text: "Да", action: .callback, eventPayload: .applyOrderReplacement(orderId: orderId, state: state)),
                    ]])
                ]
            }

        default:
            return app.eventLoopGroup.future(error: SendMessageGroupError.invalidPayload)
        }
    }

    func handleEventPayload(_ event: MessageEvent, _ eventPayload: EventPayload, _ replyText: inout String, context: PhotoBotContextProtocol) throws -> Future<[Botter.Message]>? {
        let (app, user, _) = (context.app, context.user, context.bot)
        
        switch eventPayload {
        case let .applyOrderReplacement(orderId, state):
            replyText = "Move"
            
            return OrderModel.find(orderId, on: app.db)
                .unwrap(or: SendMessageGroupError.invalidPayload)
                .flatMap { model in
                    model.merge(with: state)
                    return model.update(on: app.db).map { model }
                }.throwingFlatMap { (order: OrderModel) in
                    
                    guard let userFuture = state.getMergedUser(app: app) else {
                        fatalError()
                    }
                    
                    return [
                        userFuture.optionalThrowingFlatMap { try $0.toTwin(app: app) }.throwingFlatMap { user in
                            guard let user = user, let lastDestination = user.lastDestination else { return app.eventLoopGroup.future([]) }
                            return user.push(
                                .entryPoint(.orderAgreement),
                                payload: .orderAgreement(orderId: try order.requireID()),
                                to: lastDestination, context: context
                            )
                        },
                        try event.replyMessage(.init(text: "Изменения в заказе были успешно применены."), context: context).throwingFlatMap { messages in
                            try user.popToDifferentNode(to: event, context: context).map { $0 + messages }
                        }
                    ].flatten(on: app.eventLoopGroup.next()).map { $0.reduce([], +) }
                }
            
        case let .handleOrderReplacement(replacement):
            guard case let .orderReplacement(orderId, type) = user.nodePayload else {
                throw SendMessageGroupError.invalidPayload
            }

            return OrderModel.find(orderId, on: app.db)
                .throwingFlatMap { order in
                    guard let order = order else {
                        throw SendMessageGroupError.invalidPayload
                    }
                    
                    if replacement {
                        return user.push(.entryPoint(type.listNodeEntryPoint), payload: .orderBuilder(.init(type: order.type)), to: event, context: context)
                    } else {
                        order.status = .cancelled

                        return order.save(on: app.db).throwingFlatMap {
                            try event.replyMessage(.init(text: "Заказ был успешно отменен."), context: context)
                        }
                        .throwingFlatMap { _ in try user.popToMain(to: event, context: context) }
                    }
                }
        
        default:
            return nil
        }
    }
}
