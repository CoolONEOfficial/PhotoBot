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

class Node {
    
    var id: UUID?
    
    let systemic: Bool
    
    @Validated(.greater(1))
    var name: String?

    var messagesGroup: SendMessageGroup
    
    enum EntryPoint: String, Codable {
        case welcome
        case welcomeGuest
        case orderBuilder
        case orderBuilderStylist
        case orderBuilderStudio
        case orderBuilderMakeuper
        case orderCheckout
        case orderFinish
    }

    var entryPoint: EntryPoint?

    var action: NodeAction?
    
    private let model: Model?

    init(systemic: Bool = false, name: String? = nil, messagesGroup: SendMessageGroup = [], entryPoint: Node.EntryPoint? = nil, action: NodeAction? = nil) {
        self.model = nil
        self.id = nil
        self.systemic = systemic
        self.messagesGroup = messagesGroup
        self.entryPoint = entryPoint
        self.action = action
        self.name = name
    }
    
    // MARK: Modeled Type

    required init(from model: Model) throws {
        self.model = model
        self.id = try model.requireID()
        systemic = model.systemic
        messagesGroup = model.messagesGroup
        entryPoint = model.entryPoint
        action = model.action
        self.name = model.name
    }
    
}

extension Node: ModeledType {
    typealias Model = NodeModel
    
    var isValid: Bool {
        _name.isValid
    }
    
    func saveModel(app: Application) throws -> EventLoopFuture<NodeModel> {
        guard isValid, let name = name else {
            throw ModeledTypeError.validationError(self)
        }
        let model = self.model ?? .init()
        model.id = id
        model.systemic = systemic
        model.name = name
        model.messagesGroup = messagesGroup
        model.entryPoint = entryPoint
        model.action = action
        return model.save(on: app.db).map { model }
    }
}

extension Node {
    public static func find(
        _ target: PushTarget,
        on database: Database
    ) -> Future<Node> {
        Model.find(target, on: database).flatMapThrowing { try $0.toMyType() }
    }
    
    public static func findId(
        _ target: PushTarget,
        on database: Database
    ) -> Future<UUID> {
        Model.find(target, on: database).map(\.id!)
    }
    
    
//    public static func find(
//        entryPoint: EntryPoint,
//        on database: Database
//    ) -> Future<Node> {
//        Model.find(entryPoint, on: database).flatMapThrowing { try! $0.toMyType() }
//    }
//
//    public static func findId(
//        entryPoint: EntryPoint,
//        on database: Database
//    ) -> Future<UUID> {
//        Self.find(entryPoint: entryPoint, on: database).map(\.id!)
//    }
    
//    public static func findId(
//        targets: [PushTarget],
//        app: Application
//    ) -> Future<[PushTarget: UUID]> {
//        targets.map { target in
//            Self.findId(target, on: app.db)
//        }.flatten(on: app.eventLoopGroup.next()).map { ids in
//            ids.enumerated().reduce([EntryPoint: UUID]()) { map, entry in
//                var map = map
//                map[targets[entry.offset]] = entry.element
//                return map
//            }
//        }
//    }
}
