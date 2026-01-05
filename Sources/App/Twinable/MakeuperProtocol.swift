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

protocol MakeuperProtocol: PhotosProtocol, UsersProtocol, PlatformIdentifiable, Priceable, Twinable {

    associatedtype ImplementingModel = MakeuperModel
    associatedtype SiblingModel = MakeuperPhoto

    var id: UUID? { get set }
    var name: String? { get set }
    var user: UserModel! { get set }

    init()
    static func create(id: UUID?, name: String?, platformIds: [TypedPlatform<UserPlatformId>], photos: [PlatformFileModel]?, prices: [OrderType: Float], user: UserModel?, app: Application) -> Future<Self>
}

fileprivate enum MakeuperCreateError: Error {
    case noUser
}

extension MakeuperProtocol where TwinType: MakeuperProtocol {
    static func create(other: TwinType, app: Application) throws -> Future<Self> {
        [
            other.getUser(app: app).map { $0 as Any },
            other.getPhotos(app: app).map { $0 as Any },
        ].flatten(on: app.eventLoopGroup.next()).flatMap {
            let (user, photos) = ($0[0] as? UserModel, $0[1] as? [PlatformFileModel])
            return Self.create(id: other.id, name: other.name, platformIds: other.platformIds, photos: photos, prices: other.prices, user: user, app: app)
        }
    }

    static func create(id: UUID? = nil, name: String?, platformIds: [TypedPlatform<UserPlatformId>], photos: [PlatformFileModel]?, prices: [OrderType: Float], user: UserModel? = nil, app: Application) -> Future<Self> {
        var instance = Self.init()
        instance.id = id
        instance.name = name
        instance.platformIds = platformIds
        instance.prices = prices
        return instance.saveIfNeeded(app: app).throwingFlatMap {
            var futures = [
                try $0.attachPhotos(photos, app: app),
            ]
            
            if let user = user {
                futures.append(try $0.attachUser(user, app: app))
            }
            
            return futures
                .flatten(on: app.eventLoopGroup.next())
                .transform(to: instance)
        }
    }
}
