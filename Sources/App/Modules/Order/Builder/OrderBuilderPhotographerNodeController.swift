//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 12.06.2021.
//

import Foundation
import Botter
import Vapor

class OrderBuilderPhotographerNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            name: "Order builder photographer node",
            messagesGroup: .list(.photographers),
            entryPoint: .orderBuilderPhotographer, app: app
        )
    }
    
    func getListSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol, listType: MessageListType, indexRange: Range<Int>) throws -> EventLoopFuture<([SendMessage], Int)>? {
        guard listType == .photographers else { return nil }
        let (app, user) = (context.app, context.user)
        guard case let .orderBuilder(state) = payload, let orderType = state.type else { throw SendMessageGroupError.invalidPayload }
        let model = PhotographerModel.self
        return model.query(on: app.db).count().flatMap { count in
            model.query(on: app.db).filter(.sql(raw: "prices ? '\(orderType.rawValue)'")).range(indexRange).all().flatMap { humans in
                humans.enumerated().map { (index, human) -> Future<SendMessage> in
                    human.$_photos.get(on: app.db).throwingFlatMap { photos -> Future<SendMessage> in
                        try photos.map { try PlatformFile.create(other: $0, app: app) }
                            .flatten(on: app.eventLoopGroup.next())
                            .flatMapThrowing { attachments -> SendMessage in
                                SendMessage(
                                    text: "\(human.name ?? "")\n\(human.prices[orderType]!) ₽ / час\n\(human.platformLink(for: platform) ?? "")",
                                    keyboard: [ [
                                        try Button(
                                            text: "Выбрать",
                                            action: .callback,
                                            eventPayload: .selectPhotographer(id: try human.requireID())
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
        guard case let .selectPhotographer(photographerId) = eventPayload else { return nil }
        let (app, user) = (context.app, context.user)

        guard let nodeId = user.history.firstOrderBuildable?.nodeId else {
            fatalError()
        }

        replyText = "Selected"
        return Photographer.find(photographerId, app: app).throwingFlatMap { photographer in
            try user.push(.id(nodeId), payload: .orderBuilder(.init(with: user.history.last?.nodePayload, photographer: photographer)), to: event, saveMove: false, context: context)
        }
        
    }
}
