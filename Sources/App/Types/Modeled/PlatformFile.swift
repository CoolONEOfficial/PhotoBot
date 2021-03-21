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

final class PlatformFile: PlatformFileProtocol {
    
    typealias TwinType = PlatformFileModel
    
    var id: UUID?
    
    @Validated(.contains(.tg, .vk))
    var platformEntries: [Entry]?
    
    var type: FileInfoType?
    
    required init() {}
    
}

extension PlatformFile: ModeledType {
    
    var isValid: Bool {
        _platformEntries.isValid
    }
    
    func save(app: Application) throws -> EventLoopFuture<PlatformFileModel> {
        guard isValid else {
            throw ModeledTypeError.validationError(self)
        }
        return try TwinType.create(other: self, app: app)
    }
}

extension PlatformFile {
    
    var fileInfo: FileInfo? {
        guard let platformEntries = platformEntries, let type = type else { return nil }
        return .init(type: type, content: .fileId(.init(platformEntries)))
    }
    
}

extension Array where Element: Model {
    func attach<From: Model, Through: Model>(to: SiblingsProperty<From, Element, Through>, app: Application) throws -> Future<Void> {
        compactMap { to.attach($0, on: app.db) }.flatten(on: app.eventLoopGroup.next())
    }
}
