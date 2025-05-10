//
//  Prescription.swift
//  Carehub
//
//  Created by user@87 on 23/04/25.
//

import SwiftUI
import FirebaseFirestore

struct Prescription {
    var Medicines: [Medicine]
    var appointmentId: String
    var createdAt: Date
    var doctorId: String
    var patientId: String
    var prescriptionId: String
}

struct Medicine{
    var Dosage: String
    var Duration: Int
    var Frequency: String
    var Instructions: String
    var Name: String
}
