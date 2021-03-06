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
    
    associatedtype SiblingModel: Model
    associatedtype PhotoModel: Model
    
    var photos: [PlatformFileModel] { get set }
    var photosSiblings: AttachableFileSiblings<SiblingModel, PhotoModel>? { get }
}

extension PhotosProtocol {
    func getPhotos(app: Application) -> Future<[PlatformFileModel]> {
        photosSiblings?.get(on: app.db) ?? app.eventLoopGroup.future(photos)
    }

    var photosSiblings: AttachableFileSiblings<SiblingModel, PhotoModel>? { nil }
    
    func attachPhotos(photos: [PlatformFileModel]?, app: Application) throws -> Future<Void> {
        guard let photos = photos else { return app.eventLoopGroup.future() }

        if let _ = self as? AnyModel {
            guard let siblings = self.photosSiblings else { fatalError("Photos siblings must be implemented") }
            return try photos.attach(to: siblings, app: app)
        } else {
            self.photos = photos
            return app.eventLoopGroup.future()
        }
    }
}
