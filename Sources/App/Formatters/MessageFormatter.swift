//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.01.2021.
//

import Foundation
import Vapor
import Botter

enum ReplacingKey: AutoCodable {
    
    case username
    case userId
    case userFirstName
    case userLastName
    case stylist
    case makeuper
    case studio
    case price
    case totalPrice
    case admin
    case orderDate

    case promoBlock
    case priceBlock
    case orderBlock(showLinks: Bool = false)
    
//    var name: String {
//        switch self {
//        case .username: return "$USERNAME"
//        case .userId: return "$USER_ID"
//        case .userFirstName: return "$USER_FIRST_NAME"
//        case .userLastName: return "$USER_LAST_NAME"
//        case .stylist: return "$STYLIST"
//        case .makeuper: return "$MAKEUPER"
//        case .studio: return "$STUDIO"
//        case .price: return "$PRICE"
//        case .totalPrice: return "$TOTAL_PRICE"
//        case .admin: return "$ADMIN"
//        case .orderDate: return "$ORDERDATE"
//
//        case .promoBlock: return "$PROMO_BLOCK"
//        case .priceBlock: return "$PRICE_BLOCK"
//        case .orderBlock: return "$ORDER_BLOCK"
//        }
//    }

//    func encode() throws -> String {
//        String(data: try JSONEncoder.snakeCased.encode(self), encoding: .utf8)! + "|"
//    }
//
//    init(string: String) throws {
//        self = try JSONDecoder.snakeCased.decode(Self.self, from: string.data(using: .utf8)!)
//    }
}

extension ReplacingKey: CaseIterable {
    static var allCases: [Self] = [
        .username,
        .userId,
        .userFirstName,
        .userLastName,
        .stylist,
        .makeuper,
        .studio,
        .price,
        .totalPrice,
        .admin,
        .orderDate,

        .promoBlock,
        .priceBlock,
        .orderBlock()
    ]
}

extension ReplacingKey {
    static let nope = "<nope>"
    static let notSelected = "Не выбран"
    
    func appending(dict: ReplacingDict, platform: AnyPlatform, user: User, app: Application) -> Future<ReplacingDict> {
        var dict = dict
        
        switch self {
        case .username, .userId, .userLastName, .userFirstName:
            let userPlatformId = user.platformIds.firstValue(platform: platform)
            dict[.username] = userPlatformId?.username ?? Self.nope
            dict[.userId] = (try? userPlatformId?.id.encodeToString()) ?? Self.nope
            dict[.userFirstName] = user.firstName ?? Self.nope
            dict[.userFirstName] = user.firstName ?? Self.nope
            dict[.userLastName] = user.lastName ?? Self.nope

        case .admin:
            dict[.admin] = Application.adminNickname(for: platform)

        case .orderDate:
            switch user.nodePayload {
            case let .checkout(state):
                return Self.handleOrderState(state: state.order, dict: dict, platform: platform, app: app)

            case let .orderBuilder(state):
                return Self.handleOrderState(state: state, dict: dict, platform: platform, app: app)
                
            default: break
            }

        case .promoBlock, .priceBlock, .price, .totalPrice, .stylist, .makeuper, .studio:
            var future: Future<ReplacingDict> = app.eventLoopGroup.future(dict)
            
            var orderState: OrderState?
            switch user.nodePayload {
            case let .checkout(state):
                orderState = state.order
                
                future = future.flatMap { dict in
                    state.promotions.map { Promotion.find($0, app: app) }.flatten(on: app.eventLoopGroup.next())
                        .map { $0.compactMap { $0 } }
                        .map { promotions in
                        
                            let price = Float(state.order.price)
                            
                            let priceBlockElements = ["Сумма: " + .replacing(by: .price)]
                                + promotions.map { $0.impact.description(for: price) }
                                + ["Общая стоимость: " + .replacing(by: .totalPrice)]
                            
                            var promoBlock = promotions.isEmpty ? "" : ("Примененные акции: " + promotions.compactMap { $0.name }.joined(separator: ", ") + "\n")
                            if !promotions.contains(where: { $0.promocode != nil }) {
                                promoBlock += "Если у тебя есть промокод пришли его в ответ на это сообщение и он будет применен\n"
                            }
                            
                            var dict = dict
                            dict[.promoBlock] = promoBlock
                            dict[.priceBlock] = priceBlockElements.joined(separator: "\n")
                            dict[.totalPrice] = promotions.applying(to: price)
                            return dict
                        }
                }
            
            case let .orderBuilder(state):
                orderState = state
            
            default:
                orderState = nil
            }
            
            return future.flatMap { dict in
                Self.handleOrderState(state: orderState, dict: dict, platform: platform, app: app)
            }

        case .orderBlock(let showLinks): break
            
        }
        return app.eventLoopGroup.future(dict)
    }
    
    private static func handleOrderState(state: OrderState?, dict: [ReplacingKey: CustomStringConvertible], platform: AnyPlatform, app: Application) -> Future<ReplacingDict> {
        var future = app.eventLoopGroup.future(())
        var dict = dict

        dict[.stylist] = Self.notSelected
        if let stylistId = state?.stylistId {
            future = future.flatMap { string in
                StylistModel.find(stylistId, on: app.db).map { stylist in
                    if let stylistName = stylist?.name {
                        let link = stylist?.platformLink(for: platform)
                        dict[.stylist] = stylistName + (link != nil ? " (\(link!))" : "")
                    }
                }
            }
        }

        dict[.makeuper] = Self.notSelected
        if let makeuperId = state?.makeuperId {
            future = future.flatMap { string in
                MakeuperModel.find(makeuperId, on: app.db).map { makeuper in
                    if let makeuperName = makeuper?.name {
                        let link = makeuper?.platformLink(for: platform)
                        dict[.makeuper] = makeuperName + (link != nil ? " (\(link!))" : "")
                    }
                }
            }
        }

        dict[.studio] = Self.notSelected
        if let studioId = state?.studioId {
            future = future.flatMap { string in
                StudioModel.find(studioId, on: app.db).map { studio in
                    dict[.studio] = studio?.name ?? Self.notSelected
                }
            }
        }

        dict[.orderDate] = Self.notSelected
        if let date = state?.date, let duration = state?.duration {
            dict[.orderDate] = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short) + " - " + DateFormatter.localizedString(from: date.addingTimeInterval(duration), dateStyle: .none, timeStyle: .short)
        }
        
        dict[.price] = state?.price ?? 0

        return future.map { dict }
    }
}

extension ReplacingKey: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(try! encodeToString())
    }
}

extension String {
    static func replacing(by key: ReplacingKey) -> Self {
        "|" + (try! key.encodeToString()!) + "|"
    }
}

typealias ReplacingDict = [ReplacingKey: CustomStringConvertible]

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
    
    private func testFormat(_ string: String, dict: ReplacingDict, platform: AnyPlatform, user: User, app: Application) -> Future<String> {
        if let start = string.firstIndex(of: "|"),
           let end = string.secondIndex(of: "|") {
            let range = start...end
            let replacingString = String(string[range].dropLast().dropFirst())
            let key = try! ReplacingKey(from: replacingString)
            
            let future: Future<(ReplacingDict, String)>
            
            var string = string
            if let val = dict[key] {
                string.replaceSubrange(range, with: val.description)
                future = app.eventLoopGroup.future((dict, string))
            } else {
                future = key.appending(dict: dict, platform: platform, user: user, app: app).map { dict in
                    string.replaceSubrange(range, with: dict[key]!.description)
                    return (dict, string)
                }
            }
        
            return future.flatMap { self.testFormat($0.1, dict: $0.0, platform: platform, user: user, app: app) }
        }
        return app.eventLoopGroup.future(string)
    }
    
    func format(_ string: String, platform: AnyPlatform, user: User, app: Application) -> Future<String> {
        let userPlatformId = user.platformIds.firstValue(platform: platform)
        
        let initialDict: ReplacingDict = [
            .userFirstName: user.firstName ?? ReplacingKey.nope,
            .userLastName: user.lastName ?? ReplacingKey.nope,
            .admin: Application.adminNickname(for: platform),
            .userId: (try? userPlatformId?.id.encodeToString()) ?? ReplacingKey.nope,
            .username: userPlatformId?.username ?? ReplacingKey.nope,
        ]
        
        return testFormat(string, dict: initialDict, platform: platform, user: user, app: app)
    }
    
}
