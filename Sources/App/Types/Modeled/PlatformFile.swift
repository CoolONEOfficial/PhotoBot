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
    
//    private let model: Model?
//
//    init(platform: [Entry], type: FileInfoType) {
//        self.model = nil
//        self.id = nil
//        self.type = type
//        self.platformEntries = platform
//    }
    
    // MARK: Modeled Type
//
//    required init(from model: Model) throws {
//        self.model = model
//        self.id = try model.requireID()
//        self.type = model.type
//        self.platformEntries = model.platformEntries
//    }
    
}

extension PlatformFile: ModeledType {
    
    var isValid: Bool {
        _platformEntries.isValid
    }
    
    func saveModel(app: Application) throws -> EventLoopFuture<PlatformFileModel> {
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

typealias AttachableFileSiblings<From: Model, Through: Model> = SiblingsProperty<From, PlatformFileModel, Through>

extension Array where Element == PlatformFileModel {
    func attach<From: Model, Through: Model>(to: AttachableFileSiblings<From, Through>, app: Application) throws -> Future<Void> {
        compactMap { to.attach($0, on: app.db) }.flatten(on: app.eventLoopGroup.next())
    }
}
