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
        case orderContructor
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
    
    func toModel() throws -> Model {
        guard let name = name else {
            throw ModeledTypeError.validationError(self)
        }
        let model = self.model ?? .init()
        model.id = id
        model.systemic = systemic
        model.name = name
        model.messagesGroup = messagesGroup
        model.entryPoint = entryPoint
        model.action = action
        return model
    }
}

extension Node {
    public static func find(
        _ action: NodeAction.`Type`,
        on database: Database
    ) -> Future<Node> {
        Model.find(action, on: database).flatMapThrowing { try $0.toMyType() }
    }
    
    public static func find(
        _ entryPoint: EntryPoint,
        on database: Database
    ) -> Future<Node> {
        Model.find(entryPoint, on: database).flatMapThrowing { try! $0.toMyType() }
    }
    
//    func editableMessages(_ user: User, canEditText: Bool) -> [SendMessage]? {
//        if case var .array(messages) = messagesGroup {
////            if !systemic, user.isValid {
////                for (index, params) in messages.enumerated() {
////                    params.keyboard.buttons.insert([
////                        try! Button(
////                            text: "Edit text",
////                            action: .callback,
////                            eventPayload: .editText(messageId: index)
////                        )
//////                        try! Button( TODO: node creation
//////                            text: "Add node",
//////                            action: .callback,
//////                            eventPayload: .createNode(type: .node)
//////                        )
////                    ], at: 0)
////                    messages[index] = params
////                }
////            }
//            return messages
//        }
//        return nil
//    }
}
