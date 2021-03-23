//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 20.03.2021.
//

import Foundation
import Botter
import Vapor

class OrderBuilderStylistNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            name: "Order builder stylist node",
            messagesGroup: .list(.stylists),
            entryPoint: .orderBuilderStylist, app: app
        )
    }
    
    func getListSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol, listType: MessageListType, indexRange: Range<Int>) throws -> EventLoopFuture<([SendMessage], Int)>? {
        guard listType == .stylists else { return nil }
        let app = context.app
        let model = StylistModel.self
        return model.query(on: app.db).count().flatMap { count in
            model.query(on: app.db).range(indexRange).all().flatMap { humans in
                humans.enumerated().map { (index, human) -> Future<SendMessage> in
                    human.$_photos.get(on: app.db).throwingFlatMap { photos -> Future<SendMessage> in
                        try photos.map { try PlatformFile.create(other: $0, app: app) }
                            .flatten(on: app.eventLoopGroup.next())
                            .flatMapThrowing { attachments -> SendMessage in
                                SendMessage(
                                    text: "\(human.name ?? "")\n\(human.price) ₽ / час\n\(human.platformLink(for: platform) ?? "")",
                                    keyboard: [ [
                                        try Button(
                                            text: "Выбрать",
                                            action: .callback,
                                            eventPayload: .selectStylist(id: try human.requireID())
                                        )
                                    ] ],
                                    attachments: attachments.compactMap { $0.fileInfo }
                                )

                            }
                    }
                }
                .flatten(on: app.eventLoopGroup.next())
                .map { ($0, count) }
            }
        }
    }
    
    func handleEventPayload(_ event: MessageEvent, _ eventPayload: EventPayload, _ replyText: inout String, context: PhotoBotContextProtocol) throws -> EventLoopFuture<[Message]>? {
        guard case let .selectStylist(stylistId) = eventPayload else { return nil }
        let (app, user) = (context.app, context.user)
        
        replyText = "Selected"
        return Node.find(.entryPoint(.orderBuilder), app: app).flatMap { node in
            Stylist.find(stylistId, app: app).throwingFlatMap { stylist in
                try user.push(node, payload: .orderBuilder(.init(with: user.history.last?.nodePayload, stylist: stylist)), to: event, saveMove: false, context: context)
            }
            
        }
    }
}
