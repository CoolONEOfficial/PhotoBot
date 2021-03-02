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

protocol MakeuperProtocol: PhotosProtocol, Cloneable where TwinType: MakeuperProtocol {

    associatedtype SiblingModel = MakeuperModel
    associatedtype PhotoModel = MakeuperPhoto

    var id: UUID? { get set }
    var name: String? { get set }

    init()
    static func create(id: UUID?, name: String?, photos: [PlatformFileModel]?, app: Application) -> Future<Self>
}

extension MakeuperProtocol {
    static func create(other: TwinType, app: Application) -> Future<Self> {
        Self.create(id: other.id, name: other.name, photos: other.photos, app: app)
    }

    static func create(id: UUID? = nil, name: String?, photos: [PlatformFileModel]?, app: Application) -> Future<Self> {
        let instance = Self.init()
        instance.id = id
        instance.name = name
        return instance.saveIfNeeded(app: app).throwingFlatMap {
            try $0.attachPhotos(photos: photos, app: app).transform(to: instance)
        }
    }
}
