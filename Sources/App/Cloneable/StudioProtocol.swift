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

protocol StudioProtocol: PhotosProtocol, Priceable, Cloneable where TwinType: StudioProtocol {
    var id: UUID? { get set }
    var name: String? { get set }
    var description: String? { get set }
    var address: String? { get set }
    var coords: Coords? { get set }

    init()
    static func create(id: UUID?, name: String?, description: String?, address: String?, coords: Coords?, photos: [PlatformFileModel]?, price: Int, app: Application) -> Future<Self>
}

extension StudioProtocol {
    var photosSiblings: AttachableFileSiblings<StudioModel, StudioPhoto>? { nil }
    
    static func create(other: TwinType, app: Application) -> Future<Self> {
        other.getPhotos(app: app).flatMap { photos in
            Self.create(id: other.id, name: other.name, description: other.description, address: other.address, coords: other.coords, photos: photos, price: other.price, app: app)
        }
    }
    
    static func create(id: UUID? = nil, name: String?, description: String?, address: String?, coords: Coords?, photos: [PlatformFileModel]?, price: Int, app: Application) -> Future<Self> {
        var instance = Self.init()
        instance.id = id
        instance.name = name
        instance.description = description
        instance.address = address
        instance.coords = coords
        instance.price = price
        return instance.saveIfNeeded(app: app).throwingFlatMap {
            try $0.attachPhotos(photos: photos, app: app).transform(to: instance)
        }
    }
}
