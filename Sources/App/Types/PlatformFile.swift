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
    
    @Validated(.contains(.tg, .vk))
    var platformEntries: [Entry]?
    
    var type: FileInfoType
    
    private let model: Model?

    init(platform: [Entry], type: FileInfoType) {
        self.model = nil
        self.id = nil
        self.type = type
        self.platformEntries = platform
    }
    
    // MARK: Modeled Type

    required init(from model: Model) throws {
        self.model = model
        self.id = try model.requireID()
        self.type = model.type
        self.platformEntries = model.platformEntries
    }
    
}

extension PlatformFile: ModeledType {
    typealias Model = PlatformFileModel
    
    var isValid: Bool {
        _platformEntries.isValid
    }
    
    func toModel() throws -> Model {
        guard let platform = platformEntries else {
            throw ModeledTypeError.validationError(self)
        }
        let model = self.model ?? .init()
        model.type = type
        model.platformEntries = platform
        return model
    }
}

extension PlatformFile {
    
    var fileInfo: FileInfo? {
        guard let platformEntries = platformEntries else { return nil }
        return .init(type: type, content: .fileId(.init(platformEntries)))
    }
    
}
