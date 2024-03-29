//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 20.03.2021.
//

import Foundation
import Botter
import Vapor

class OrderBuilderStudioNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            name: "Order builder studio node",
            messagesGroup: .list(.studios),
            entryPoint: .orderBuilderStudio, app: app
        )
    }
    
    func getListSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol, listType: MessageListType, indexRange: Range<Int>) throws -> EventLoopFuture<([SendMessage], Int)>? {
        guard listType == .studios else { return nil }
        let (app, user) = (context.app, context.user)
        guard case let .orderBuilder(state) = payload, let orderType = state.type else { throw SendMessageGroupError.invalidPayload }
        let model = StudioModel.self
        return model.query(on: app.db).count().flatMap { count in
            model.query(on: app.db).filter(.sql(raw: "prices ? '\(orderType.rawValue)'")).range(indexRange).all().flatMap { studios in
                studios.enumerated().map { (index, studio) -> Future<SendMessage> in
                    studio.$_photos.get(on: app.db).throwingFlatMap { photos -> Future<SendMessage> in
                        try photos.map { try PlatformFile.create(other: $0, app: app) }
                            .flatten(on: app.eventLoopGroup.next())
                            .flatMapThrowing { attachments -> SendMessage in
                                SendMessage(
                                    text: "\(studio.name ?? "")\n\(studio.prices[orderType]!) ₽ / час",
                                    keyboard: [ [
                                        try Button(
                                            text: "Выбрать",
                                            action: .callback,
                                            eventPayload: .selectStudio(id: try studio.requireID())
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
        guard case let .selectStudio(studioId) = eventPayload else { return nil }
        let (app, user) = (context.app, context.user)
        
        guard let nodeId = user.history.firstOrderBuildable?.nodeId else {
            fatalError()
        }

        replyText = "Selected"
        return Studio.find(studioId, app: app).throwingFlatMap { studio in
            try user.push(.id(nodeId), payload: .orderBuilder(.init(with: user.history.last?.nodePayload, studio: studio)), to: event, saveMove: false, context: context)
        }

    }
}
