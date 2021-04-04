//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 13.01.2021.
//

import Foundation
import Botter
import Vapor

public class SendMessage: Codable {
    
    public var destination: SendDestination?

    /// Текст личного сообщения.
    public var text: String?
    
    public var formatText: Bool
    
    /// Объект, описывающий клавиатуру бота.
    public var keyboard: Keyboard
    
    /// Вложения прикрепленные к сообщению.
    public var attachments: [FileInfo]?
    
    var params: Bot.SendMessageParams? {
        Bot.SendMessageParams(to: self, text: text, keyboard: keyboard, attachments: attachments)
    }
    
    convenience init(to replyable: Replyable, text: String? = nil, formatText: Bool = true, keyboard: Keyboard = .init(), attachments: [FileInfo]? = nil) {
        self.init(destination: replyable.destination, text: text, keyboard: keyboard, attachments: attachments)
    }
    
    init(destination: SendDestination? = nil, text: String? = nil, formatText: Bool = true, keyboard: Keyboard = .init(), attachments: [FileInfo]? = nil) {
        self.destination = destination
        self.text = text
        self.formatText = formatText
        self.keyboard = keyboard
        self.attachments = attachments
    }
}

extension SendMessage: Replyable {}
