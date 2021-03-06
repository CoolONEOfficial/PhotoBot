//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 27.02.2021.
//

import Foundation
import Vapor
import Fluent
import Botter

struct UserHistoryEntry: Codable {
    let nodeId: UUID
    let nodePayload: NodePayload?
}

protocol UserProtocol: Cloneable where TwinType: UserProtocol {
    
    var id: UUID? { get set }
    var history: [UserHistoryEntry] { get set }
    var nodeId: UUID? { get set }
    var nodePayload: NodePayload? { get set }
    var vkId: Int64? { get set }
    var tgId: Int64? { get set }
    var name: String? { get set }
    
    init()
    static func create(id: UUID?, history: [UserHistoryEntry], nodeId: UUID?, nodePayload: NodePayload?, vkId: Int64?, tgId: Int64?, name: String?, app: Application) -> Future<Self>
}

extension UserProtocol {
    static func create(other: TwinType, app: Application) -> Future<Self> {
        Self.create(id: other.id, history: other.history, nodeId: other.nodeId, nodePayload: other.nodePayload, vkId: other.vkId, tgId: other.tgId, name: other.name, app: app)
    }
    
    static func create(id: UUID? = nil, history: [UserHistoryEntry] = [], nodeId: UUID? = nil, nodePayload: NodePayload? = nil, vkId: Int64? = nil, tgId: Int64? = nil, name: String?, app: Application) -> Future<Self> {
        let instance = Self.init()
        instance.id = id
        instance.history = history
        instance.nodeId = nodeId
        instance.nodePayload = nodePayload
        instance.vkId = vkId
        instance.tgId = tgId
        instance.name = name
        return instance.saveIfNeeded(app: app)
    }
}
