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
import AnyCodable

class Human<Model: HumanModel> {

    var id: UUID?
    
    @Validated(.isLetters && .greater(1) && .less(25))
    var name: String?

    @Validated(.nonEmpty)
    var photos: [PlatformFile]?
    
    private let model: Model?
    
    init(name: String? = nil, photos: [PlatformFile]) {
        self.id = nil
        self.model = nil
        self.photos = photos
        self.name = name
    }

    // MARK: Modeled Type
    
    required init(from model: Model) throws {
        self.model = model
        id = model.id
        photos = try model.photos.map { try $0.toMyType() }
        name = model.name
    }
    
}

extension Human: ModeledType {
    func toModel() throws -> Model {
        guard isValid else {
            throw ModeledTypeError.validationError(self)
        }
        let model = self.model ?? .init()
        model.id = id
        model.name = name
        return model
    }
    
    var isValid: Bool {
        _name.isValid && _photos.isValid
    }
}
