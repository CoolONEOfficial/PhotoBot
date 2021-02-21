//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 14.02.2021.
//

import Foundation
import ValidatedPropertyKit
import Botter
import Vapor
import Fluent
import AnyCodable

class Stylist {
    
    @Validated(.isLetters && .greater(1) && .less(25))
    var name: String?

    @Validated(.nonEmpty)
    var photos: [PlatformFile]?
    
    private let model: Model?
    
    init(name: String? = nil, photos: [PlatformFile]) {
        self.model = nil
        self.photos = photos
        self.name = name
    }

    // MARK: Modeled Type
    
    required init(from model: Model) throws {
        self.model = model
        photos = try model.photos.map { try $0.toMyType() }
        name = model.name
    }
    
}

extension Stylist: ModeledType {
    typealias Model = StylistModel
    
    func toModel() throws -> Model {
        guard isValid else {
            throw ModeledTypeError.validationError(self)
        }
        let model = self.model ?? .init()
        model.name = name
        return model
    }
    
    var isValid: Bool {
        _name.isValid && _photos.isValid
    }
}
