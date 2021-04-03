//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 26.02.2021.
//

import Foundation
import Vapor
import Fluent
import Botter

public enum EntryPoint: String, Codable {
    case welcome
    case welcomeGuest
    case showcase
    case orderTypes
    case orderBuilder
    case orderBuilderStylist
    case orderBuilderStudio
    case orderBuilderMakeuper
    case orderBuilderDate
    case orderCheckout
    case about
    case portfolio
    case orders
    case uploadPhoto
    case reviews
    case messageEdit
    case orderAgreement
}
 
protocol NodeProtocol: Twinable where TwinType: NodeProtocol {
    var id: UUID? { get set }
    var systemic: Bool { get set }
    var name: String? { get set }
    var messagesGroup: SendMessageGroup! { get set }
    var entryPoint: EntryPoint? { get set }
    var action: NodeAction? { get set }
    
    init()
    static func create(id: UUID?, systemic: Bool, name: String?, messagesGroup: SendMessageGroup, entryPoint: EntryPoint?, action: NodeAction?, app: Application) -> Future<Self>
}

enum NodeCreateError: Error {
    case noMessageGroup
}

extension NodeProtocol {
    static func create(other: TwinType, app: Application) throws -> Future<Self> {
        guard let messagesGroup = other.messagesGroup else { throw NodeCreateError.noMessageGroup }
        return Self.create(id: other.id, systemic: other.systemic, name: other.name, messagesGroup: messagesGroup, entryPoint: other.entryPoint, action: other.action, app: app)
    }
    
    static func create(id: UUID? = nil, systemic: Bool = false, name: String?, messagesGroup: SendMessageGroup, entryPoint: EntryPoint? = nil, action: NodeAction? = nil, app: Application) -> Future<Self> {
        let instance = Self.init()
        instance.id = id
        instance.systemic = systemic
        instance.name = name
        instance.messagesGroup = messagesGroup
        instance.entryPoint = entryPoint
        instance.action = action
        return instance.saveIfNeeded(app: app)
    }
}
