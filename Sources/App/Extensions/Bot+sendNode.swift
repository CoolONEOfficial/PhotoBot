//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 08.01.2021.
//

import Botter
import Vapor

extension Bot {
    func sendNode<R: Replyable & PlatformObject>(to replyable: R, node: Node, payload: NodePayload?, platform: AnyPlatform, context: PhotoBotContextProtocol) throws -> Future<[Botter.Message]>? {
        try node.messagesGroup?.getSendMessages(platform: replyable.platform.any, in: node, payload, context: context).throwingFlatMap { messages -> Future<[Botter.Message]> in
            let (app, user) = (context.app, context.user)
            var future: Future<[Botter.Message]> = app.eventLoopGroup.future([])
            
            for params in messages {
                params.destination = replyable.destination
                future = future.flatMap { messages in
                    params.keyboard.buttons.map { buttons in
                        buttons.map(\.payload).map { payload -> Future<String?> in
                            guard let payload = payload else { return app.eventLoopGroup.future(nil) }
                            if payload.count > 64 {
                                return EventPayloadModel(instance: payload, ownerId: user.id!, nodeId: user.nodeId!)
                                    .saveWithId(on: app.db)
                                    .flatMapThrowing { id in
                                        switch platform {
                                        case .tg: // tg payload is just string like "blahblah"
                                            return String(describing: id)
                                        case .vk: // vk payload is json string like "\"blahblah\""
                                            return try id.encodeToString()!
                                        }
                                    }
                            } else {
                                return app.eventLoopGroup.future(payload)
                            }
                        }.flatten(on: app.eventLoopGroup.next())
                    }.flatten(on: app.eventLoopGroup.next()).throwingFlatMap { buttonPayloads in
                        for (index, list) in buttonPayloads.enumerated() {
                            for (innerIndex, payload) in list.enumerated() {
                                if let payload = payload {
                                    params.keyboard.buttons[index][innerIndex].payload = payload
                                }
                            }
                        }
                        
                        return try self.sendMessage(
                            params.params!,
                            platform: platform,
                            context: context
                        ).map { messages + $0 }
                    }
                }
            }
            
            return future
        }
    }
}
