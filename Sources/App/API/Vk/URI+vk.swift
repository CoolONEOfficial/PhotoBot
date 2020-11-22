//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 22.11.2020.
//

import Vapor

extension URI {
    private enum Method: String {
        case sendMessage = "messages.send"
    }
    
    private static func vkMethod(method: Method, args: [String: String]) -> URI {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.vk.com"
        components.path = "/method/\(method)"
        components.queryItems = args.merging([
            "v": "5.126",
            "access_token": Application.vkToken
        ]).queryItems

        return .init(string: components.string!)
    }

    static func vkMessage(_ message: VkEvent.Object.Message) -> URI {
        vkMethod(
            method: .sendMessage,
            args: [
                "random_id": String(Int64.random()),
                "peer_id": String(message.peer_id),
                "message": message.text,
            ]
        )
    }
}

private extension Dictionary where Key == String, Value == String {
    var queryItems: [URLQueryItem] {
        enumerated().map { .init(
            name: $0.element.key,
            value: $0.element.value
        ) }
    }
}
