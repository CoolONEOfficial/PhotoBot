//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 02.03.2021.
//

import Foundation
import Vapor
import Fluent
import Botter

protocol PhotosProtocol: class {
    
    associatedtype ImplementingModel: Model & PhotosProtocol
    associatedtype SiblingModel: Model
    
    var photos: [PlatformFileModel] { get set }
    var photosSiblings: AttachableFileSiblings<ImplementingModel, SiblingModel>? { get }
}

extension PhotosProtocol where Self: Twinable, Self.TwinType == ImplementingModel {
    var photosSiblings: AttachableFileSiblings<ImplementingModel, SiblingModel>? { nil }
}

extension PhotosProtocol {
    func getPhotos(app: Application) -> Future<[PlatformFileModel]> {
        photosSiblings?.get(on: app.db) ?? app.eventLoopGroup.future(photos)
    }
    
    func attachPhotos(_ photos: [PlatformFileModel]?, app: Application) throws -> Future<Void> {
        guard let photos = photos else { return app.eventLoopGroup.future() }

        if let model = self as? ImplementingModel {
            guard let siblings = model.photosSiblings else { fatalError("Photos siblings must be implemented") }
            return try photos.attach(to: siblings, app: app)
        } else {
            self.photos = photos
            return app.eventLoopGroup.future()
        }
    }
}
