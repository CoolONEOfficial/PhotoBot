//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.01.2021.
//

import Foundation
import Vapor
import Botter

enum ReplacingKey: String, CaseIterable {
    
    case username
    case userId
    case userFirstName
    case userLastName
    case stylist
    case makeuper
    case photographer
    case studio
    case price
    case totalPrice
    case admin
    case orderDate
    case orderType
    case orderStatus
    case orderId
    case orderCustomer

    case promoBlock
    case priceBlock
    case orderBlock
}

extension ReplacingKey {
    static let nope = "<nope>"
    static let notSelected = "Не выбран"
    
    func appending(dict: ReplacingDict, platform: AnyPlatform, user: User, app: Application) -> Future<ReplacingDict> {
        var dict = dict
        
        var orderState: OrderState?
        switch user.nodePayload {
        case let .checkout(state):
            orderState = state.order
        
        case let .orderBuilder(state):
            orderState = state
        
        default:
            orderState = nil
        }
        
        switch self {
        case .username, .userId, .userLastName, .userFirstName:
            let userPlatformId = user.platformIds.firstValue(platform: platform)
            dict[.username] = [userPlatformId?.username ?? Self.nope]
            dict[.userId] = [(try? userPlatformId?.id.encodeToString()) ?? Self.nope]
            dict[.userFirstName] = [user.firstName ?? Self.nope]
            dict[.userFirstName] = [user.firstName ?? Self.nope]
            dict[.userLastName] = [user.lastName ?? Self.nope]

        case .admin:
            dict[.admin] = [Application.adminNickname(for: platform)]

        case .promoBlock, .priceBlock, .price, .totalPrice,
             .stylist, .makeuper, .studio, .photographer, .orderDate, .orderType,
             .orderStatus, .orderId, .orderCustomer:
            var future: Future<ReplacingDict> = app.eventLoopGroup.future(dict)
            
            if case let .checkout(state) = user.nodePayload {
                future = future.flatMap { dict in
                    state.promotions.map { Promotion.find($0.id, app: app) }.flatten(on: app.eventLoopGroup.next())
                        .map { $0.compactMap { $0 } }
                        .map { promotions in
                        
                            var dict = dict
                            
                            var promoBlockElements = [String]()
                            if !promotions.contains(where: { $0.promocode != nil }) {
                                promoBlockElements.append("Если у тебя есть промокод пришли его в ответ на это сообщение и он будет применен")
                            }
                            dict[.promoBlock] = promoBlockElements
                            
                            let price = state.order.price
                            let priceBlockElements = ["Сумма: " + .replacing(by: .price)]
                                + promotions.map { promo in
                                    var str = promo.impact.description(for: price)
                                    
                                    if let caption = promo.promocode ?? promo.name {
                                        str += " (\(caption))"
                                    }
                                    
                                    return str
                                }
                                + ["Общая стоимость: " + .replacing(by: .totalPrice)]
                            dict[.priceBlock] = priceBlockElements
                            dict[.totalPrice] = ["\(promotions.applying(to: price)) ₽"]
                            return dict
                        }
                }
            }
            
            return future.flatMap { dict in
                Self.handleOrderState(state: orderState, dict: dict, platform: platform, app: app)
            }

        case .orderBlock:
            
            guard let orderState = orderState else { break }
            
            var str = [
                "Тип: " + .replacing(by: .orderType),
                "Фотограф: " + .replacing(by: .photographer),
                "Студия: " + .replacing(by: .studio),
                "Дата: " + .replacing(by: .orderDate),
            ]
            
            switch orderState.type {
            case .family, .loveStory:
                str.insert(contentsOf: [
                    "Стилист: " + .replacing(by: .stylist),
                    "Визажист: " + .replacing(by: .makeuper),
                ], at: 2)
                
            default:
                break
            }
            
            if user.isAdmin || orderState.watchers.contains(user.id!), orderState.status != nil {
                str.insert("Статус: " + .replacing(by: .orderStatus), at: 0)
            }
            
            dict[self] = [str.joined(separator: "\n")]
        }
        return app.eventLoopGroup.future(dict)
    }
    
    private static func handleOrderState(state: OrderState?, dict: ReplacingDict, platform: AnyPlatform, app: Application) -> Future<ReplacingDict> {
        var future = app.eventLoopGroup.future(())
        var dict = dict

        dict[.stylist] = [Self.notSelected]
        if let stylistId = state?.stylistId {
            future = future.flatMap { string in
                StylistModel.find(stylistId, on: app.db).map { stylist in
                    if let stylistName = stylist?.name {
                        let link = stylist?.platformLink(for: platform)
                        dict[.stylist] = [stylistName + (link != nil ? " (\(link!))" : "")]
                    }
                }
            }
        }

        dict[.makeuper] = [Self.notSelected]
        if let makeuperId = state?.makeuperId {
            future = future.flatMap { string in
                MakeuperModel.find(makeuperId, on: app.db).map { makeuper in
                    if let makeuperName = makeuper?.name {
                        let link = makeuper?.platformLink(for: platform)
                        dict[.makeuper] = [makeuperName + (link != nil ? " (\(link!))" : "")]
                    }
                }
            }
        }
        
        dict[.photographer] = [Self.notSelected]
        if let photographerId = state?.photographerId {
            future = future.flatMap { string in
                PhotographerModel.find(photographerId, on: app.db).map { photographer in
                    if let photographerName = photographer?.name {
                        let link = photographer?.platformLink(for: platform)
                        dict[.photographer] = [photographerName + (link != nil ? " (\(link!))" : "")]
                    }
                }
            }
        }

        dict[.studio] = [Self.notSelected]
        if let studioId = state?.studioId {
            future = future.flatMap { string in
                StudioModel.find(studioId, on: app.db).map { studio in
                    dict[.studio] = [studio?.name ?? Self.notSelected]
                }
            }
        }
        
        dict[.orderCustomer] = [Self.nope]
        if let userId = state?.userId {
            future = future.flatMap { string in
                UserModel.find(userId, on: app.db).map { user in
                    dict[.orderCustomer] = [user?.firstName ?? Self.notSelected]
                }
            }
        }

        dict[.orderDate] = [Self.notSelected]
        if let date = state?.date, let duration = state?.duration {
            dict[.orderDate] = [DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short) + " - " + DateFormatter.localizedString(from: date.addingTimeInterval(duration), dateStyle: .none, timeStyle: .short)]
        }
        
        dict[.orderType] = [Self.notSelected]
        if let orderType = state?.type.name {
            dict[.orderType] = [orderType]
        }
        
        dict[.orderId] = [Self.notSelected]
        if let orderId = state?.id {
            dict[.orderId] = [orderId]
        }
        
        dict[.orderStatus] = [Self.notSelected]
        if let status = state?.status?.description {
            dict[.orderStatus] = [status]
        }

        let price = state?.price ?? 0
        dict[.price] = ["\(price) ₽\(state?.duration == nil ? " / ч" : "")"]

        return future.map { dict }
    }
}

extension String {
    static func replacing(by key: ReplacingKey) -> Self {
        "|" + key.rawValue + "|"
    }
}

typealias ReplacingDict = [ReplacingKey: [CustomStringConvertible]]

extension String {
    func indicesOf(string: String) -> [Index] {
        var indices = [Index]()
        var searchStartIndex = self.startIndex

        while searchStartIndex < self.endIndex,
            let range = self.range(of: string, range: searchStartIndex..<self.endIndex),
            !range.isEmpty
        {
            let index = range.lowerBound
            indices.append(index)
            searchStartIndex = range.upperBound
        }

        return indices
    }
}

extension Collection where Element: Equatable {
    /// Returns the second index where the specified value appears in the collection.
    func secondIndex(of element: Element) -> Index? {
        guard let index = firstIndex(of: element) else { return nil }
        return self[self.index(after: index)...].firstIndex(of: element)
    }
}

class MessageFormatter {
    static let shared = MessageFormatter()
    
    private init() {}
    
    func format(_ string: String, platform: AnyPlatform?, context: PhotoBotContextProtocol) -> Future<String> {
        let platform = platform ?? context.platform
        let (_, user) = (context.app, context.user)
        let userPlatformId = user.platformIds.firstValue(platform: platform)
        
        let initialDict: ReplacingDict = [
            .userFirstName: [user.firstName ?? ReplacingKey.nope],
            .userLastName: [user.lastName ?? ReplacingKey.nope],
            .admin: [Application.adminNickname(for: platform)],
            .userId: [(try? userPlatformId?.id.encodeToString()) ?? ReplacingKey.nope],
            .username: [userPlatformId?.username ?? ReplacingKey.nope],
        ]
        
        return format(string, dict: initialDict, platform: platform, context: context)
    }
    
    private func format(_ string: String, dict: ReplacingDict, platform: AnyPlatform, context: PhotoBotContextProtocol) -> Future<String> {
        let (app, user) = (context.app, context.user)
        
        if let start = string.firstIndex(of: "|"),
           let end = string.secondIndex(of: "|") {
            let range = start...end
            let replacingString = String(string[range].dropLast().dropFirst())
            if let key = ReplacingKey(rawValue: replacingString) {
                let future: Future<(ReplacingDict, String)>
                
                var string = string
                if let val = dict[key] {
                    string.replaceSubrange(range, with: val.map(\.description).joined(separator: "\n"))
                    future = app.eventLoopGroup.future((dict, string))
                } else {
                    future = key.appending(dict: dict, platform: platform, user: user, app: app).map { dict in
                        string.replaceSubrange(range, with: dict[key]!.map(\.description).joined(separator: "\n"))
                        return (dict, string)
                    }
                }
            
                return future.flatMap { self.format($0.1, dict: $0.0, platform: platform, context: context) }
            }
        }
        return app.eventLoopGroup.future(string)
    }
    
}
