//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 08.01.2021.
//

import Botter
import Vapor

extension Replyable where Self: PlatformObject {
    func replyNode(node: Node, payload: NodePayload?, context: PhotoBotContextProtocol) throws -> Future<[Message]>? {
        try context.bot.sendNode(to: self, node: node, payload: payload, platform: platform.any, context: context)
    }
}
