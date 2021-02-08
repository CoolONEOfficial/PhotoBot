//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 08.01.2021.
//

import Botter
import Vapor

extension Replyable where Self: PlatformObject {
    func replyNode(with bot: Bot, user: User, node: Node, app: Application) throws -> Future<[Message]>? {
        try bot.sendNode(to: self, user: user, node: node, platform: platform, app: app)
    }
}
