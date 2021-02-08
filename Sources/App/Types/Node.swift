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
        case welcome_guest
    }

    var entryPoint: EntryPoint?

    var action: NodeAction?

    var toModel: NodeModel? {
        guard let name = name else { return nil }
        let model = self.model ?? .init()
        
        model.systemic = systemic
        model.name = name
        model.messagesGroup = messagesGroup
        model.entryPoint = entryPoint
        model.action = action
        return model
    }
    
    private let model: NodeModel?

    init(systemic: Bool = false, name: String? = nil, messagesGroup: SendMessageGroup = [], entryPoint: Node.EntryPoint? = nil, action: NodeAction? = nil) {
        self.model = nil
        self.id = nil
        self.systemic = systemic
        self.messagesGroup = messagesGroup
        self.entryPoint = entryPoint
        self.action = action
        self.name = name
    }

    required init(from model: NodeModel) throws { // model
        self.model = model
        self.id = try model.requireID()
        systemic = model.systemic
        messagesGroup = model.messagesGroup
        entryPoint = model.entryPoint
        action = model.action
        self.name = model.name
    }
    
    var isValid: Bool {
        _name.isValid
    }
    
    public static func find(
        _ action: NodeAction.`Type`,
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
    
    func editableMessages(_ user: User) -> [SendMessage]? {
        if case var .array(messages) = messagesGroup {
            if !systemic, user.isValid {
                for (index, params) in messages.enumerated() {
                    params.keyboard.buttons.insert([
                        try! Button(
                            text: "Edit text",
                            action: .callback,
                            eventPayload: .editText(messageId: index)
                        ),
                        try! Button(
                            text: "Add node",
                            action: .callback,
                            eventPayload: .createNode(type: .node)
                        )
                    ], at: 0)
                    messages[index] = params
                }
            }
            return messages
        }
        return nil
    }
}
