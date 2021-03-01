//
//  File.swift
//
//
//  Created by Nickolay Truhin on 07.01.2021.
//

import Foundation
import ValidatedPropertyKit
import Botter
import Vapor
import Fluent

final class Node: NodeProtocol {
    
    typealias TwinType = NodeModel
    
    var id: UUID?
    
    var systemic: Bool?
    
    @Validated(.greater(1))
    var name: String?

    var messagesGroup: SendMessageGroup?
    
    var entryPoint: EntryPoint?

    var action: NodeAction?
    
    required init() {}
}

extension Node: ModeledType {
    var isValid: Bool {
        _name.isValid
    }
    
    func saveModel(app: Application) throws -> EventLoopFuture<NodeModel> {
        guard isValid else {
            throw ModeledTypeError.validationError(self)
        }
        return try TwinType.create(other: self, app: app)
    }
}

extension Node {
    public static func find(
        _ target: PushTarget,
        app: Application
    ) -> Future<Node> {
        TwinType.find(target, on: app.db).throwingFlatMap { try Node.create(other: $0, app: app) }
    }
    
    public static func findId(
        _ target: PushTarget,
        app: Application
    ) -> Future<UUID> {
        Self.find(target, app: app).map(\.id!)
    }
}
