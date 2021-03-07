//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 08.01.2021.
//

import Botter
import Vapor

extension InputReplyable where Self: PlatformObject {
    func replyNode(with bot: Bot, user: User, node: Node, payload: NodePayload?, app: Application) throws -> Future<[Message]>? {
        try bot.sendNode(to: self, user: user, node: node, payload: payload, platform: platform, app: app)
    }
}
