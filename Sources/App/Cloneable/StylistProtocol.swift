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

protocol StylistProtocol: PhotosProtocol, PlatformIdentifiable, Priceable, Twinable where TwinType: StylistProtocol {
    
    associatedtype SiblingModel = StylistModel
    associatedtype PhotoModel = StylistPhoto

    var id: UUID? { get set }
    var name: String? { get set }

    init()
    static func create(id: UUID?, name: String?, platformIds: [TypedPlatform<UserPlatformId>], photos: [PlatformFileModel]?, price: Int, app: Application) -> Future<Self>
}

extension StylistProtocol {
    static func create(other: TwinType, app: Application) throws -> Future<Self> {
        other.getPhotos(app: app).flatMap { photos in
            Self.create(id: other.id, name: other.name, platformIds: other.platformIds, photos: photos, price: other.price, app: app)
        }
    }
    
    static func create(id: UUID? = nil, name: String?, platformIds: [TypedPlatform<UserPlatformId>], photos: [PlatformFileModel]?, price: Int, app: Application) -> Future<Self> {
        var instance = Self.init()
        instance.id = id
        instance.name = name
        instance.price = price
        instance.platformIds = platformIds
        return instance.saveIfNeeded(app: app).throwingFlatMap {
            try $0.attachPhotos(photos: photos, app: app).transform(to: instance)
        }
    }
}
