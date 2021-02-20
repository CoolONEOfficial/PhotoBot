//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 21.02.2021.
//

import Foundation
import ValidatedPropertyKit
import Botter
import Vapor
import Fluent

class PlatformFile {
    
    var id: UUID?
    
    typealias Entry = Platform<String, String>
    
    // TODO: @validated
    var platform: [Entry]
    
    private let model: Model?

    init(platform: [Entry]) {
        self.model = nil
        self.id = nil
        self.platform = platform
    }
    
    // MARK: Modeled Type

    required init(from model: Model) throws {
        self.model = model
        self.id = try model.requireID()
        self.platform = model.platform
    }
    
}

extension PlatformFile: ModeledType {
    typealias Model = PlatformFileModel
    
    var isValid: Bool {
        true
    }
    
    func toModel() throws -> Model {
//        guard let name = name else {
//            throw ModeledTypeError.validationError(self)
//        }
        let model = self.model ?? .init()
        
        model.platform = platform
        return model
    }
}
