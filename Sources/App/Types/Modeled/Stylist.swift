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

final class Stylist: StylistProtocol {

    typealias TwinType = StylistModel
    
    var id: UUID?

    @Validated(.greater(1))
    var name: String?

    @Validated(.nonEmpty)
    var photos: [PlatformFileModel]?

    required init() {}

    // TODO: contact info (vk or tg id/username)

}

extension Stylist: PhotoModeledType {
    typealias PhotoModel = StylistPhoto
}

extension Stylist: ModeledType {
    var isValid: Bool {
        _name.isValid && _photos.isValid
    }

    func saveModel(app: Application) throws -> EventLoopFuture<TwinType> {
        guard isValid else {
            throw ModeledTypeError.validationError(self)
        }
        return try TwinType.create(other: self, app: app)
    }
}

