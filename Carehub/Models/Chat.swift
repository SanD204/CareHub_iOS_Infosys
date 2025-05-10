//
//  Chat.swift
//  Carehub
//
//  Created by user@87 on 23/04/25.
//

import SwiftUI
import FirebaseFirestore

struct Chat{
    var chatid: String
    var messages: [Message]
}

struct Message{
    var id: String
    var text: String
    var messageld: String
    var recieverId: String
    var senderId: String
    var timestamp: Date
}
