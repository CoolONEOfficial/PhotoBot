//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 13.01.2021.
//

import Foundation
import Botter
import Vapor

class SendMessage: Codable {
    
    public var chatId: Int64?
    
    public var userId: Int64?

    /// Текст личного сообщения.
    public var text: String?
    
    /// Объект, описывающий клавиатуру бота.
    public var keyboard: Keyboard
    
    /// Вложения прикрепленные к сообщению.
    public var attachments: [FileInfo]?
    
    var params: Bot.SendMessageParams {
        .init(to: self, text: text, keyboard: keyboard, attachments: attachments)
    }
    
    convenience init(to replyable: Replyable, text: String? = nil, keyboard: Keyboard = .init(), attachments: [FileInfo]? = nil) {
        self.init(chatId: replyable.chatId, userId: replyable.userId, text: text, keyboard: keyboard, attachments: attachments)
    }
    
    init(chatId: Int64? = nil, userId: Int64? = nil, text: String? = nil, keyboard: Keyboard = .init(), attachments: [FileInfo]? = nil) {
        self.chatId = chatId
        self.userId = userId
        self.text = text
        self.keyboard = keyboard
        self.attachments = attachments
    }
}

extension SendMessage: Replyable {}
