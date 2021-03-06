//
//  File.swift
//
//
//  Created by Nickolay Truhin on 10.01.2021.
//

import Foundation
import Fluent
import Botter
import Vapor
import ValidatedPropertyKit

enum ModeledTypeError: Error {
    case validationError(_ type: Any)
}

protocol ModeledType: Cloneable where TwinType: Model {
    
    func save(app: Application) throws -> Future<TwinType>
    
    var isValid: Bool { get }
}

extension ModeledType {
    var isValid: Bool { true }
    
    func saveReturningId(app: Application) throws -> Future<TwinType.IDValue> {
        try save(app: app).flatMapThrowing { try $0.requireID() }
    }
}
