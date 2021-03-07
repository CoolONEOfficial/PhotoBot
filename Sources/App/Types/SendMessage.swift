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
    
//    public var chatId: Int64?
//
//    public var userId: Int64?
    
    public var destination: SendDestination?

    /// Текст личного сообщения.
    public var text: String?
    
    /// Объект, описывающий клавиатуру бота.
    public var keyboard: Keyboard
    
    /// Вложения прикрепленные к сообщению.
    public var attachments: [FileInfo]?
    
    var params: Bot.SendMessageParams? {
        Bot.SendMessageParams(to: self, text: text, keyboard: keyboard, attachments: attachments)
    }
    
    convenience init(to replyable: InputReplyable, text: String? = nil, keyboard: Keyboard = .init(), attachments: [FileInfo]? = nil) {
        self.init(destination: replyable.destination, text: text, keyboard: keyboard, attachments: attachments)
    }
    
    init(//chatId: Int64? = nil, userId: Int64? = nil,
        destination: SendDestination? = nil, text: String? = nil, keyboard: Keyboard = .init(), attachments: [FileInfo]? = nil) {
//        self.chatId = chatId
//        self.userId = userId
        self.destination = destination
        self.text = text
        self.keyboard = keyboard
        self.attachments = attachments
    }
}

extension SendMessage: OutputReplyable {}
