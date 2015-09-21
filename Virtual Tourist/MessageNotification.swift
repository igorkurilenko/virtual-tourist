//
//  MessageNotification.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/21/15.
//  Copyright © 2015 igor kurilenko. All rights reserved.
//

import Foundation

enum MessageStyle {
    case Success, Error, Default
}

class MessageNotification {
    var message: Message
    var messageStyle: MessageStyle
    
    init(message: Message, messageStyle: MessageStyle) {
        self.message = message
        self.messageStyle = messageStyle
    }
    
    convenience init(message: Message) {
        self.init(message: message, messageStyle: .Default)
    }
    
}

struct Message {
    var title: String
    var description: String
    
    init(title: String, description: String){
        self.title = title
        self.description = description
    }
    
    static func create(error: NSError) -> Message {
        var message:Message
        
        switch(error.domain) {
        case NSURLErrorDomain:
            message = Message(
                title: "A networking error has occured",
                description: error.localizedDescription
            )
            
        case VirtualTouristErrorDomain:
            message = Message(
                title: error.localizedDescription,
                description: error.localizedFailureReason!
            )
            
        default:
            message = Message(
                title: "An error has occured",
                description: "Unknown error.")
        }
        
        return message
    }
}