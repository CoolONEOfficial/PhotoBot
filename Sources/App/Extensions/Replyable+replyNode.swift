//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 08.01.2021.
//

import Botter
import Vapor

extension Replyable {
    func replyNode(from bot: Bot, node: Node, app: Application) throws -> Future<[Message]>? {
        guard let fromId = fromId else { return nil }
        return try bot.sendNode(to: fromId, node: node, platform: platform, app: app)
    }
}
