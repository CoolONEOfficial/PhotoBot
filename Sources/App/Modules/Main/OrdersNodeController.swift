//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 20.03.2021.
//

import Foundation
import Botter
import Vapor

class OrdersNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            systemic: true,
            name: "Orders node",
            messagesGroup: .list(.orders),
            entryPoint: .orders, app: app
        )
    }
    
    func getListSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol, listType: MessageListType, indexRange: Range<Int>) throws -> EventLoopFuture<([SendMessage], Int)>? {
        guard listType == .orders else { return nil }
        let app = context.app
        
        return OrderModel.query(on: app.db).count().flatMap { count in
            OrderModel.query(on: app.db).range(indexRange).all().throwingFlatMap { orders in
                try orders.enumerated().map { (index, model) -> Future<SendMessage> in
                    try Order.create(other: model, app: app).flatMap { order in
                        context.user.nodePayload = .checkout(order.state)
                        return MessageFormatter.shared.format(
                            [
                                "Заказ от @" + .replacing(by: .username) + " (" + .replacing(by: .userId) + "):",
                                .replacing(by: .orderBlock),
                                .replacing(by: .priceBlock),
                            ].joined(separator: "\n"),
                            platform: platform,
                            context: context
                        ).map { text in
                            SendMessage(
                                text: text
                            )
                        }
                    }
                }.flatten(on: app.eventLoopGroup.next())
            }
            .map { ($0, count) }
        }
    }

}
