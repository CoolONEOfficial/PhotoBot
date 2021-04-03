//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 20.03.2021.
//

import Foundation
import Botter
import Vapor

enum ReviewsError {
    case screenshotNotFound
}

class ReviewsNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            name: "Reviews node",
            messagesGroup: .list(.reviews),
            entryPoint: .reviews, app: app
        )
    }
    
    func getListSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol, listType: MessageListType, indexRange: Range<Int>) throws -> EventLoopFuture<([SendMessage], Int)>? {
        guard listType == .reviews else { return nil }
        let (app, _) = (context.app, context.user)
        
        return ReviewModel.query(on: app.db).count().flatMap { count in
            ReviewModel.query(on: app.db).range(indexRange).all().throwingFlatMap { orders in
                orders.enumerated().map { (index, order) -> Future<SendMessage?> in
                    order.$_screenshot.get(on: app.db).throwingFlatMap { screenshot -> Future<SendMessage?> in
                        guard let screenshot = screenshot else { return app.eventLoopGroup.future(nil) }
                        return try screenshot.toTwin(app: app).map { screenshot in
                            guard let attachment = screenshot.fileInfo else { return nil }
                            return SendMessage(
                                attachments: [ attachment ]
                            )
                        }
                    }
                }
                .flatten(on: app.eventLoopGroup.next())
                .map { ($0.compactMap { $0 }, count) }
            }
        }
    }
}
