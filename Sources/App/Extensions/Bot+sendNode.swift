//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 08.01.2021.
//

import Botter
import Vapor

extension Bot {
    func sendNode<R: Replyable, Tg, Vk>(to replyable: R, user: User, node: Node, payload: NodePayload?, platform: Platform<Tg, Vk>, app: Application) throws -> Future<[Botter.Message]> {
        try node.messagesGroup.getSendMessages(in: node, app: app, user, payload).throwingFlatMap { messages in
            var future: Future<[Botter.Message]> = app.eventLoopGroup.future([])
            
            for params in messages {
                var params = params
                params.setDestination(to: replyable)
                future = future.throwingFlatMap { messages in
                    try self.sendMessage(
                        params: params.params,
                        platform: platform, app: app
                    ).map { messages + [$0] }
                }
            }
            
            return future
        }
        
//        try node.editableMessages(user)?.enumerated().compactMap { (index, params) in
//            var params = params
//            params.setDestination(to: replyable)
//            return try self.sendMessage(
//                params: params.params,
//                platform: platform, app: app
//            )
//        }.flatten(on: app.eventLoopGroup.next())
    }
}
