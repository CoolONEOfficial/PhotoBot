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
    
    private let model: Model?
    
    init(name: String? = nil) {
        self.model = nil
        self.name = name
    }

    // MARK: Modeled Type
    
    required init(from model: Model) {
        self.model = model
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
        _name.isValid
    }
}
