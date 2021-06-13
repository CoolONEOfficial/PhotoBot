//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 20.03.2021.
//

import Foundation
import Botter
import Vapor

class OrderBuilderMakeuperNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            name: "Order builder makeuper node",
            messagesGroup: .list(.makeupers),
            entryPoint: .orderBuilderMakeuper, app: app
        )
    }
    
    func getListSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol, listType: MessageListType, indexRange: Range<Int>) throws -> EventLoopFuture<([SendMessage], Int)>? {
        guard listType == .makeupers else { return nil }
        let (app, user) = (context.app, context.user)
        guard case let .orderBuilder(state) = payload, let orderType = state.type else { throw SendMessageGroupError.invalidPayload }

        return MakeuperModel.query(on: app.db).count().flatMap { count in
            MakeuperModel.query(on: app.db).filter(.sql(raw: "prices ? '\(orderType.rawValue)'")).range(indexRange).all().flatMap { humans in
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
                                            eventPayload: .selectMakeuper(id: try human.requireID())
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
        guard case let .selectMakeuper(makeuperId) = eventPayload else { return nil }
        let (app, user) = (context.app, context.user)
        
        guard let nodeId = user.history.firstOrderBuildable?.nodeId else {
            fatalError()
        }

        replyText = "Selected"
        return Makeuper.find(makeuperId, app: app).throwingFlatMap { makeuper in
            try user.push(.id(nodeId), payload: .orderBuilder(.init(with: user.history.last?.nodePayload, makeuper: makeuper)), to: event, saveMove: false, context: context)
        }
        
    }
}
