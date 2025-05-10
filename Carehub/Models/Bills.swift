//
//  Bills.swift
//  Carehub
//
//  Created by user@87 on 23/04/25.
//

import SwiftUI
import FirebaseFirestore

struct Billing: Identifiable, Codable {
    var id: String { billingId }
    let billingId: String
    let bills: [BillItem]
    let appointmentId: String
    let billingStatus: String
    let date: Date
    let doctorId: String
    let insuranceAmt: Double
    let paidAmt: Double
    let patientId: String
    let paymentMode: String
    var billURL: String?
    
    func toDictionary() -> [String: Any] {
        return [
            "billingId": billingId,
            "bills": bills.map { $0.toDictionary() },
            "appointmentId": appointmentId,
            "billingStatus": billingStatus,
            "date": Timestamp(date: date),
            "doctorId": doctorId,
            "insuranceAmt": insuranceAmt,
            "paidAmt": paidAmt,
            "patientId": patientId,
            "paymentMode": paymentMode,
            "billURL": billURL
        ]
    }
}

struct BillItem: Codable {
    let fee: Double
    let isPaid: Bool
    let itemName: String
    
    func toDictionary() -> [String: Any] {
        return [
            "fee": fee,
            "isPaid": isPaid,
            "itemName": itemName
        ]
    }
}
