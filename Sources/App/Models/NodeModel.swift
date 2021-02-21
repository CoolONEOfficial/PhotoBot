//
//  NodeModel.swift
//  
//
//  Created by Nickolay Truhin on 08.01.2021.
//

import Fluent
import Vapor
import Botter

final class NodeModel: Model, Content {
    static let schema = "nodes"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "systemic")
    var systemic: Bool
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "messages")
    var messagesGroup: SendMessageGroup
    
    @OptionalField(key: "entry_point")
    var entryPoint: Node.EntryPoint?
    
    @OptionalField(key: "action")
    var action: NodeAction?

    init() { }

    init(id: UUID? = nil, systemic: Bool = false, name: String, messagesGroup: SendMessageGroup, entryPoint: Node.EntryPoint? = nil, action: NodeAction? = nil) {
        self.id = id
        self.systemic = systemic
        self.name = name
        self.messagesGroup = messagesGroup
        self.entryPoint = entryPoint
        self.action = action
    }
    
    public static func find(
        _ action: NodeAction.`Type`,
        on database: Database
    ) -> Future<NodeModel> {
        query(on: database).filter(.sql(raw: "action->>\'type\'"), .equal, .enumCase(action.rawValue)).first()
            .unwrap(or: PhotoBotError.node_by_action_not_found)
    }
    
    public static func find(
        _ entryPoint: Node.EntryPoint,
        on database: Database
    ) -> Future<NodeModel> {
        query(on: database).filter(\.$entryPoint == .enumCase(entryPoint.rawValue)).first()
            .unwrap(or: PhotoBotError.node_by_entry_point_not_found)
    }
}

extension NodeModel: TypedModel { typealias MyType = Node }
