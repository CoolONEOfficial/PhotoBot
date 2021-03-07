//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 08.01.2021.
//

import Botter
import Vapor

extension Bot {
    func sendNode<R: InputReplyable & PlatformObject, Tg, Vk>(to replyable: R, user: User, node: Node, payload: NodePayload?, platform: Platform<Tg, Vk>, app: Application) throws -> Future<[Botter.Message]>? {
        try node.messagesGroup?.getSendMessages(platform: replyable.platform.any, in: node, app: app, user, payload).throwingFlatMap { messages -> Future<[Botter.Message]> in
            var future: Future<[Botter.Message]> = app.eventLoopGroup.future([])
            
            for params in messages {
                params.destination = replyable.destination
                future = future.flatMap { messages in
                    params.keyboard.buttons.map { buttons in
                        buttons.compactMap(\.payload).map { payload -> Future<String> in
                            if payload.count > 64 {
                                return EventPayloadModel(payload)
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
                    }.flatten(on: app.eventLoopGroup.next()).throwingFlatMap { payloadIds in
                        for (index, list) in payloadIds.enumerated() {
                            for (innerIndex, id) in list.enumerated() {
                                params.keyboard.buttons[index][innerIndex].payload = String(id)
                            }
                        }
                        
                        return try self.sendMessage(
                            params: params.params!,
                            platform: platform, app: app
                        ).map { messages + [$0] }
                    }
                }
            }
            
            return future
        }
    }
}
