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

protocol StudioProtocol: PhotosProtocol, Cloneable where TwinType: StudioProtocol {
    var id: UUID? { get set }
    var name: String? { get set }
    var description: String? { get set }
    var address: String? { get set }
    var coords: Coords? { get set }

    init()
    static func create(id: UUID?, name: String?, description: String?, address: String?, coords: Coords?, photos: [PlatformFileModel]?, app: Application) throws -> Future<Self>
}

extension StudioProtocol {
    var photosSiblings: AttachableFileSiblings<StudioModel, StudioPhoto>? { nil }
    
    static func create(other: TwinType, app: Application) throws -> Future<Self> {
        try Self.create(id: other.id, name: other.name, description: other.description, address: other.address, coords: other.coords, photos: other.photos, app: app)
    }
    
    static func create(id: UUID? = nil, name: String?, description: String?, address: String?, coords: Coords?, photos: [PlatformFileModel]?, app: Application) throws -> Future<Self> {
        let instance = Self.init()
        instance.id = id
        instance.name = name
        instance.description = description
        instance.address = address
        instance.coords = coords
        return instance.saveIfNeeded(app: app).throwingFlatMap {
            try $0.attachPhotos(photos: photos, app: app).transform(to: instance)
        }
    }
}
