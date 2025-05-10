//
//  Accountant.swift
//  Carehub
//
//  Created by user@87 on 23/04/25.
//
import SwiftUI
import FirebaseFirestore

struct Accountant: Identifiable, Decodable {
    var id: String { accountantId }
    var email: String
    var name: String
    var shift: Shift?
    var accountantId: String
    var createdAt: Timestamp?  // Using Firestore Timestamp
    var phoneNo: String
    var department: String
    
    // Ensuring exact field names from the database
    enum CodingKeys: String, CodingKey {
        case email = "email"
        case name = "fullName"
        case department = "department"
        case shift = "shift"
        case accountantId = "id"
        case createdAt = "joinDate"
        case phoneNo = "phoneNumber"
    }
}
