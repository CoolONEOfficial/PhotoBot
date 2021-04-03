//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 27.02.2021.
//

import Foundation
import Vapor
import Fluent
import Botter

struct UserHistoryEntry: Codable {
    let nodeId: UUID
    let nodePayload: NodePayload?
}

struct UserPlatformId: Codable {
    let id: Int64 // chatId for tg, userId for vk
    let username: String?
}

extension TypedPlatform where Tg == UserPlatformId, Vk == UserPlatformId {
    var sendDestination: SendDestination {
        switch self {
        case let .tg(tg):
            // tg doesn't support send message by username
            return .chatId(tg.id)
            
        case let .vk(vk):
            if let username = vk.username {
                return .username(username)
            }
            return .userId(vk.id)
        }
    }
}

extension TypedPlatform where Tg == UserPlatformId, Vk == UserPlatformId {
    
    private var baseString: String? {
        let str: String
        switch self {
        case let .tg(platformId):
            guard let username = platformId.username else { return nil }
            str = username
            
        case let .vk(platformId):
            if let username = platformId.username {
                str = username
            } else {
                str = "id\(String(platformId.id))"
            }
        }
        return str
    }
    
    var mention: String? {
        guard let baseString = baseString else { return nil }
        return "@\(baseString)"
    }
    
    private var platformUrlPrefix: String {
        switch self {
        case .tg:
            return "https://t.me/"
            
        case .vk:
            return "https://vk.com/"
        }
    }
    
    var link: String? {
        guard let baseString = baseString else { return nil }
        return platformUrlPrefix + baseString
    }

}

//protocol UserMakeuperProtocol {
//    var makeuper: MakeuperModel? { get set }
//    var makeuperId: UUID? { get set }
//}
//
//extension UserMakeuperProtocol where Self: Twinable, Self.TwinType: Model {
//    var makeuperId: UUID? { nil }
//}
//
//extension UserMakeuperProtocol {
//    func getMakeuper(app: Application) ->
//}

protocol UserProtocol: PlatformIdentifiable, Twinable where TwinType: UserProtocol {
    
    var id: UUID? { get set }
    var history: [UserHistoryEntry] { get set }
    var nodeId: UUID? { get set }
    var nodePayload: NodePayload? { get set }
    var isAdmin: Bool { get set }
    var firstName: String? { get set }
    var lastName: String? { get set }
    var makeuper: MakeuperModel? { get set }
    var makeuperId: UUID? { get }
    var stylist: StylistModel? { get set }
    var stylistId: UUID? { get }
    var photographer: PhotographerModel? { get set }
    var photographerId: UUID? { get }
    
    init()
    static func create(id: UUID?, history: [UserHistoryEntry], nodeId: UUID?, nodePayload: NodePayload?, platformIds: [TypedPlatform<UserPlatformId>], isAdmin: Bool, firstName: String?, lastName: String?, makeuper: MakeuperModel?, stylist: StylistModel?, photographer: PhotographerModel?, app: Application) -> Future<Self>
}

extension UserProtocol {
    var watcherIds: [UUID] {
        [stylistId, photographerId, makeuperId].compactMap { $0 }
    }

    static func create(other: TwinType, app: Application) throws -> Future<Self> {
        [
            StylistModel.find(other.stylistId, on: app.db).map { $0 as Any },
            MakeuperModel.find(other.makeuperId, on: app.db).map { $0 as Any },
            PhotographerModel.find(other.photographerId, on: app.db).map { $0 as Any },
        ].flatten(on: app.eventLoopGroup.next()).flatMap {
            let (stylist, makeuper, photographer) = ($0[0] as? StylistModel, $0[1] as? MakeuperModel, $0[2] as? PhotographerModel)
            return Self.create(id: other.id, history: other.history, nodeId: other.nodeId, nodePayload: other.nodePayload, platformIds: other.platformIds, isAdmin: other.isAdmin, firstName: other.firstName, lastName: other.lastName, makeuper: makeuper, stylist: stylist, photographer: photographer, app: app)
        }
    }
    
    static func create(id: UUID? = nil, history: [UserHistoryEntry] = [], nodeId: UUID? = nil, nodePayload: NodePayload? = nil, platformIds: [TypedPlatform<UserPlatformId>], isAdmin: Bool = false, firstName: String?, lastName: String?, makeuper: MakeuperModel? = nil, stylist: StylistModel? = nil, photographer: PhotographerModel? = nil, app: Application) -> Future<Self> {
        var instance = Self.init()
        instance.id = id
        instance.history = history
        instance.nodeId = nodeId
        instance.nodePayload = nodePayload
        instance.platformIds = platformIds
        instance.isAdmin = isAdmin
        instance.firstName = firstName
        instance.lastName = lastName
        instance.makeuper = makeuper
        instance.stylist = stylist
        instance.photographer = photographer
        return instance.saveIfNeeded(app: app)
    }
}