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

enum ModeledTypeError: Error {
    case validationError(_ type: Any)
}

protocol ModeledType {
    associatedtype Model: TypedModel
    
    init(from model: Model) throws
    
    func saveModel(app: Application) throws -> Future<Model>
    
    var isValid: Bool { get }
}

extension ModeledType {
    func saveModelReturningId(app: Application) throws -> Future<Model.IDValue> {
        try saveModel(app: app).flatMapThrowing { try $0.requireID() }
    }
}

extension ModeledType where Model.MyType == Self {
    static func find(
        _ id: Self.Model.IDValue,
        on database: Database
    ) -> Future<Self> {
        Model.find(id, on: database).map {
            try! $0!.toMyType()
        }
    }
}
