//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 27.03.2021.
//

import Foundation
import Botter
import Vapor

class OrderAgreementNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            systemic: true,
            closeable: false,
            name: "Order agreement node",
            messagesGroup: .orderAgreement,
            entryPoint: .orderAgreement,
            action: .init(.handleOrderAgreement, success: .pop),
            app: app
        )
    }
    
    func getSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol, group: SendMessageGroup) throws -> EventLoopFuture<[SendMessage]>? {
        guard case .orderAgreement = group else { return nil }
        let (app, _) = (context.app, context.user)
        
        guard case let .orderAgreement(orderId) = payload else {
            return app.eventLoopGroup.future(error: SendMessageGroupError.invalidPayload)
        }
        
        return Order.find(orderId, app: app).flatMap { order in
            guard let order = order else {
                return app.eventLoopGroup.future(error: SendMessageGroupError.invalidPayload)
            }
            
            return CheckoutState.create(from: order, app: app).flatMapThrowing { checkoutState in
                context.user.nodePayload = .checkout(checkoutState)
                return [ .init(text: [
                    "Новый заказ от " + .replacing(by: .orderCustomer) + " (" + .replacing(by: .orderId) + "):",
                    .replacing(by: .orderBlock),
                    .replacing(by: .priceBlock),
                ].joined(separator: "\n"), keyboard: [ [
                    try Button(
                        text: "Принять",
                        action: .callback,
                        eventPayload: .handleOrderAgreement(orderId: orderId, agreement: true)
                    ),
                    try Button(
                        text: "Отклонить",
                        action: .callback,
                        eventPayload: .handleOrderAgreement(orderId: orderId, agreement: false)
                    )
                ] ]) ]
            }
        }
    }
    
    func handleEventPayload(_ event: MessageEvent, _ eventPayload: EventPayload, _ replyText: inout String, context: PhotoBotContextProtocol) throws -> EventLoopFuture<[Message]>? {
        guard case let .handleOrderAgreement(orderId, agreement) = eventPayload else { return nil }
        let (app, user) = (context.app, context.user)
        
        let future: EventLoopFuture<Void>
        
        if agreement {
            future = [
                try user.toTwin(app: app).map { $0 as Any },
                OrderModel.find(orderId, on: app.db).map { $0 as Any }
            ].flatten(on: app.eventLoopGroup.next()).throwingFlatMap { res in
                guard let user = res[0] as? UserModel,
                      let order = res[1] as? OrderModel else {
                    fatalError()
                }
                
                let query = AgreementModel.query(on: app.db)
                    .filter(\.$order.$id, .equal, order.id!)
                
                return [
                    order.fetchWatchersUsers(app: app).map { $0 as Any },
                    try AgreementModel(order: order, approver: user).create(on: app.db)
                        .flatMap { query.all() }.map { $0 as Any },
                ].flatten(on: app.eventLoopGroup.next()).flatMap { res in
                    guard let watchers = res[0] as? [UserModel],
                          let agreements = res[1] as? [AgreementModel] else {
                        fatalError()
                    }
                    
                    if agreements.map(\.$approver.id).sorted() == watchers.compactMap(\.id).sorted() {
                        return query.delete().throwingFlatMap {
                            order.status = .inProgress
                            return [
                                order.save(on: app.db),
                                try order.$user.get(on: app.db).throwingFlatMap { try $0.toTwin(app: app) }.throwingFlatMap {
                                    try $0.sendMessage(context: context, params: .init(text: "Ваш заказ был подтвержден всеми сотрудниками!"))
                                }.map { _ in () }
                            ].flatten(on: app.eventLoopGroup.next()).map { _ in () }
                        }
                    }
                    return app.eventLoopGroup.future()
                }
            }
            
        } else {
            guard let type = user.replacementType else {
                throw HandleActionError.nodePayloadInvalid
            }
            
            future = Order.find(orderId, app: app).optionalFlatMap { order in
                User.find(order.userId, app: app).optionalThrowingFlatMap { customer -> Future<[Message]> in
                    guard let lastDestination = customer.lastDestination else { throw HandleActionError.nodePayloadInvalid }
                    return customer.push(.entryPoint(.orderReplacement), payload: .orderReplacement(orderId: orderId, type: type), to: lastDestination, context: context)
                }
            }.map { _ in () }
        }

        return future.throwingFlatMap { try user.pop(to: event, context: context) }.map { _ in [] }
    }

}

extension UUID: Comparable {
    public static func < (lhs: UUID, rhs: UUID) -> Bool {
        lhs.uuidString < rhs.uuidString
    }
}
