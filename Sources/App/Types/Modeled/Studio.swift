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

final class Studio: StudioProtocol {
    
    typealias TwinType = StudioModel
    
    var id: UUID?
    
    var name: String?
    
    var description: String?
    
    var address: String?

    var coords: Coords?

    var photos: [PlatformFileModel] = []

    var price: Int = 0
    
    required init() {}
    
}

extension Studio: ModeledType {

    var isValid: Bool {
        true//_photos.isValid
    }
    
    func save(app: Application) throws -> Future<TwinType> {
        guard isValid else {
            throw ModeledTypeError.validationError(self)
        }
        return TwinType.create(other: self, app: app)
    }
}
