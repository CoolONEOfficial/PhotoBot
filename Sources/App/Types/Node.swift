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
    
    var systemic: Bool?
    
    @Validated(.isLetters && .greater(1) && .less(25))
    var name: String?
    
    @Validated(.nonEmpty)
    var messages: [Bot.SendMessageParams]?
    
    enum EntryPoint: String, Codable {
        case welcome
        case welcome_guest
    }

    var entryPoint: EntryPoint?

    var action: ActionPayload?

    var toModel: NodeModel? {
        guard let name = name, let systemic = systemic, let messages = messages else { return nil }
        let model = self.model ?? .init()
        
        model.systemic = systemic
        model.name = name
        model.messages = messages
        model.entryPoint = entryPoint
        model.action = action
        return model
    }
    
    private let model: NodeModel?

    init(systemic: Bool = false, name: String? = nil, messages: [Bot.SendMessageParams] = [], entryPoint: Node.EntryPoint? = nil, action: ActionPayload? = nil) {
        self.model = nil
        self.id = nil
        self.systemic = systemic
        self.messages = messages
        self.entryPoint = entryPoint
        self.action = action
        self.name = name
    }

    required init(from model: NodeModel) throws {
        self.model = model
        self.id = try model.requireID()
        systemic = model.systemic
        name = model.name
        messages = model.messages
        entryPoint = model.entryPoint
        action = model.action
    }
    
    var isValid: Bool {
        _name.isValid && _messages.isValid
    }
    
    public static func find(
        _ action: ActionPayload.`Type`,
        on database: Database
    ) -> Future<Node> {
        NodeModel.find(action, on: database).flatMapThrowing { try $0.toMyType() }
    }
    
    public static func find(
        _ entryPoint: EntryPoint,
        on database: Database
    ) -> Future<Node> {
        NodeModel.find(entryPoint, on: database).flatMapThrowing { try! $0.toMyType() }
    }
    
    var editableMessages: [Bot.SendMessageParams]? {
        if let systemic = systemic, !systemic, var messages = messages {
            for (index, var params) in messages.enumerated() {
                if params.keyboard == nil {
                    params.keyboard = .init(oneTime: false, buttons: [], inline: true)
                }
                params.keyboard?.buttons.insert([ try! Button(text: "Edit text", action: .callback, data: EditPayload(type: .edit_text, messageId: index)) ], at: 0)
                messages[index] = params
            }
            return messages
        }
        return messages
    }
}
