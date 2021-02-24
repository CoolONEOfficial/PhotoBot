//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.01.2021.
//

import Foundation
import Vapor
import Botter

class MessageFormatter {
    static let shared = MessageFormatter()
    
    enum ReplacingKey: String {
        case user = "$USER"
        case stylist = "$STYLIST"
        case makeuper = "$MAKEUPER"
        case studio = "$STUDIO"
    }
    
    func format(_ string: String, user: User, app: Application) -> Future<String> {
        let nope = "<nope>"
        let notSelected = "Не выбран"
        var replacingDict: [ReplacingKey: String] = [
            .user: user.name ?? nope,
            .stylist: notSelected,
            .makeuper: notSelected,
            .studio: notSelected
        ]

        var future = app.eventLoopGroup.future(replacingDict)
        if case let .orderBuilder(state) = user.nodePayload {
            if let stylistId = state.stylistId {
                future = future.flatMap { string in
                    StylistModel.find(stylistId, on: app.db).map { stylist in
                        if let stylistName = stylist?.name {
                            replacingDict[.stylist] = stylistName
                        }
                        return replacingDict
                    }
                }
            }
            if let makeuperId = state.makeuperId {
                future = future.flatMap { string in
                    MakeuperModel.find(makeuperId, on: app.db).map { makeuper in
                        if let makeuperName = makeuper?.name {
                            replacingDict[.makeuper] = makeuperName
                        }
                        return replacingDict
                    }
                }
            }
            if let studioId = state.studioId {
                future = future.flatMap { string in
                    StudioModel.find(studioId, on: app.db).map { studio in
                        if let studioName = studio?.name {
                            replacingDict[.studio] = studioName
                        }
                        return replacingDict
                    }
                }
            }
        }

        return future.map { dict in
            dict.reduce(string) { string, entry in
                string.replacingOccurrences(of: entry.key.rawValue, with: entry.value)
            }
        }
    }
}

extension String {
    static func replacing(by key: MessageFormatter.ReplacingKey) -> Self {
        key.rawValue
    }
}
