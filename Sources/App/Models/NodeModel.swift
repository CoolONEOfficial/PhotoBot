//
//  NodeModel.swift
//  
//
//  Created by Nickolay Truhin on 08.01.2021.
//

import Fluent
import Vapor
import Botter

final class NodeModel: Model, NodeProtocol {
    static let schema = "nodes"
    
    typealias TwinType = Node
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "systemic")
    var systemic: Bool?
    
    @Field(key: "name")
    var name: String?
    
    @Field(key: "messages")
    var messagesGroup: SendMessageGroup!
    
    @OptionalField(key: "entry_point")
    var entryPoint: EntryPoint?
    
    @OptionalField(key: "action")
    var action: NodeAction?

    required init() { }
    
    public static func find(
        _ target: PushTarget,
        on database: Database
    ) -> Future<NodeModel> {
        switch target {
        case let .id(id):
            return find(id, on: database).unwrap(or: PhotoBotError.nodeByIdNotFound)
            
        case let .entryPoint(entryPoint):
            return query(on: database).filter(\.$entryPoint == .enumCase(entryPoint.rawValue)).first()
                .unwrap(or: PhotoBotError.nodeByEntryPointNotFound(entryPoint))
        
        case let .action(action):
            return query(on: database).filter(.sql(raw: "action->>\'type\'"), .equal, .enumCase(action.rawValue)).first()
                .unwrap(or: PhotoBotError.nodeByActionNotFound)
        }
    }
}
