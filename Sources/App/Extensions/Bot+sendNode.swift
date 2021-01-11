//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 08.01.2021.
//

import Botter
import Vapor

extension Bot {
    func sendNode<Tg, Vk>(to peerId: Int64, node: Node, platform: Platform<Tg, Vk>, app: Application) throws -> Future<[Botter.Message]>? {
        try! node.editableMessages?.enumerated().compactMap { (index, params) in
            params.peerId = peerId
            return try self.sendMessage(
                params: params,
                platform: platform, app: app
            )
        }.flatten(on: app.eventLoopGroup.next())
    }
}
