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
        case username = "$USERNAME"
        case userId = "$USER_ID"
        case userFirstName = "$USER_FIRST_NAME"
        case userLastName = "$USER_LAST_NAME"
        case stylist = "$STYLIST"
        case makeuper = "$MAKEUPER"
        case studio = "$STUDIO"
        case price = "$PRICE"
        case admin = "$ADMIN"
        case orderDate = "$ORDERDATE"
    }
    
    typealias ReplacingDict = [ReplacingKey: CustomStringConvertible]
    
    func format(_ string: String, platform: AnyPlatform, user: User, app: Application) -> Future<String> {
        let nope = "<nope>"
        let notSelected = "Не выбран"
        
        let userPlatformId = user.platformIds.firstValue(platform: platform)
        
        let replacingDict: ReplacingDict = [
            .userFirstName: user.firstName ?? nope,
            .userLastName: user.lastName ?? nope,
            .stylist: notSelected,
            .makeuper: notSelected,
            .studio: notSelected,
            .price: 0,
            .admin: Application.adminNickname(for: platform),
            .userId: (try? userPlatformId?.id.encodeToString()) ?? nope,
            .username: userPlatformId?.username ?? nope,
            .orderDate: notSelected
        ]

        var future = app.eventLoopGroup.future(replacingDict)
        switch user.nodePayload {
        case let .checkout(state):
            future = handleOrderState(state: state.order, replacingDict: replacingDict, app: app)

        case let .orderBuilder(state):
            future = handleOrderState(state: state, replacingDict: replacingDict, app: app)
            
        default: break
        }

        return future.map { dict in
            dict.reduce(string) { string, entry in
                string.replacingOccurrences(of: entry.key.rawValue, with: entry.value.description)
            }
        }
    }
    
    private func handleOrderState(state: OrderState, replacingDict: [ReplacingKey: CustomStringConvertible], app: Application) -> Future<ReplacingDict> {
        var future = app.eventLoopGroup.future(())
        var replacingDict = replacingDict
        if let stylistId = state.stylistId {
            future = future.flatMap { string in
                StylistModel.find(stylistId, on: app.db).map { stylist in
                    if let stylistName = stylist?.name {
                        replacingDict[.stylist] = stylistName
                    }
                }
            }
        }
        if let makeuperId = state.makeuperId {
            future = future.flatMap { string in
                MakeuperModel.find(makeuperId, on: app.db).map { makeuper in
                    if let makeuperName = makeuper?.name {
                        replacingDict[.makeuper] = makeuperName
                    }
                }
            }
        }
        if let studioId = state.studioId {
            future = future.flatMap { string in
                StudioModel.find(studioId, on: app.db).map { studio in
                    if let studioName = studio?.name {
                        replacingDict[.studio] = studioName
                    }
                }
            }
        }
        if let date = state.date {
            replacingDict[.orderDate] = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
        }
        
        replacingDict[.price] = .init(state.price)
        return future.map {
            replacingDict
        }
    }
}

extension String {
    static func replacing(by key: MessageFormatter.ReplacingKey) -> Self {
        key.rawValue
    }
}
