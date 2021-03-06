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
    
    private init() {}
    
    enum ReplacingKey: String {
        case user = "$USER"
        case stylist = "$STYLIST"
        case makeuper = "$MAKEUPER"
        case studio = "$STUDIO"
        case price = "$PRICE"
        case admin = "$ADMIN"
    }
    
    typealias ReplacingDict = [ReplacingKey: String]
    
    func format(_ string: String, platform: AnyPlatform, user: User, app: Application) -> Future<String> {
        let nope = "<nope>"
        let notSelected = "Не выбран"
        
        let replacingDict: ReplacingDict = [
            .user: user.name ?? nope,
            .stylist: notSelected,
            .makeuper: notSelected,
            .studio: notSelected,
            .price: "0",
            .admin: Application.adminNickname(for: platform)
        ]

        var future = app.eventLoopGroup.future(replacingDict)
        switch user.nodePayload {
        case let .checkout(state):
            future = handleOrderState(state: state.order, replacingDict: replacingDict, app: app, future: future)

        case let .orderBuilder(state):
            future = handleOrderState(state: state, replacingDict: replacingDict, app: app, future: future)
            
        default: break
        }

        return future.map { dict in
            dict.reduce(string) { string, entry in
                string.replacingOccurrences(of: entry.key.rawValue, with: entry.value)
            }
        }
    }
    
    private func handleOrderState(state: OrderState, replacingDict: [ReplacingKey: String], app: Application, future: Future<ReplacingDict>) -> Future<ReplacingDict> {
        var future = future
        var replacingDict = replacingDict
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
        replacingDict[.price] = .init(state.price)
        return future
    }
}

extension String {
    static func replacing(by key: MessageFormatter.ReplacingKey) -> Self {
        key.rawValue
    }
}
