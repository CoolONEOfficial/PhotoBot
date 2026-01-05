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

protocol StudioProtocol: PhotosProtocol, Priceable, PlatformIdentifiable, UsersProtocol, Twinable {
    var id: UUID? { get set }
    var name: String? { get set }
    var description: String? { get set }
    var address: String? { get set }
    var coords: Coords? { get set }

    init()
    static func create(id: UUID?, name: String?, description: String?, address: String?, coords: Coords?, platformIds: [TypedPlatform<UserPlatformId>], photos: [PlatformFileModel]?, prices: [OrderType: Float], user: UserModel?, app: Application) -> Future<Self>
}

extension StudioProtocol where TwinType: StudioProtocol {
    var photosSiblings: AttachableFileSiblings<StudioModel, StudioPhoto>? { nil }

    static func create(other: TwinType, app: Application) throws -> Future<Self> {
        other.getPhotos(app: app).flatMap { photos in
            Self.create(id: other.id, name: other.name, description: other.description, address: other.address, coords: other.coords, platformIds: other.platformIds, photos: photos, prices: other.prices, app: app)
        }
    }
    
    static func create(id: UUID? = nil, name: String?, description: String?, address: String?, coords: Coords?, platformIds: [TypedPlatform<UserPlatformId>], photos: [PlatformFileModel]?, prices: [OrderType: Float], user: UserModel? = nil, app: Application) -> Future<Self> {
        var instance = Self.init()
        instance.id = id
        instance.name = name
        instance.description = description
        instance.address = address
        instance.coords = coords
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
