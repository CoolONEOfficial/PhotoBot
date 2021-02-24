//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 22.02.2021.
//

import Foundation
import ValidatedPropertyKit
import Botter
import Vapor
import Fluent

class Studio {
    
    var id: UUID?
    
    var name: String
    
    var description: String
    
    var address: String
    
    var coords: Coords
    
    @Validated(.nonEmpty)
    var photos: [PlatformFile]?
    
    private let model: Model?

    init(systemic: Bool = false, name: String, description: String, photos: [PlatformFile], address: String, coords: Coords) {
        model = nil
        id = nil
        self.name = name
        self.description = description
        self.address = address
        self.coords = coords
        self.photos = photos
    }
    
    // MARK: Modeled Type

    required init(from model: Model) throws {
        self.model = model
        self.id = try model.requireID()
        self.name = model.name
        self.description = model.description
        self.address = model.address
        self.coords = model.coords
        self.photos = try model.photos.map { try $0.toMyType() }
    }
    
}

extension Studio: PhotoModeledType {
    typealias PhotoModel = StudioPhoto
}

extension Studio: ModeledType {
    typealias Model = StudioModel
    
    var isValid: Bool {
        _photos.isValid
    }
    
    func saveModel(app: Application) throws -> Future<Model> {
        guard isValid else {
            throw ModeledTypeError.validationError(self)
        }
        let model = self.model ?? .init()
        model.id = id
        model.name = name
        model.description = description
        model.address = address
        model.coords = coords
        return model.save(on: app.db).throwingFlatMap { () -> Future<Model> in
            try self.photos?.attach(to: model.$photos, app: app).map { model } ?? app.eventLoopGroup.future(model)
        }
    }
}
