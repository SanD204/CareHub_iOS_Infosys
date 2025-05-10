import SwiftUI
import FirebaseFirestore

struct PatientF: Codable, Identifiable {
    var id: String { patientId }
    var emergencyContact: [EmergencyContact]
    var medicalRecords: [MedicalRecord]
    var testResults: [TestResultF]
    var userData: UserData
    var vitals: Vitals
    var lastModified: Date
    var patientId: String
    
    var appointments: [Appointment]?
    
    enum CodingKeys: String, CodingKey {
        case emergencyContact
        case medicalRecords
        case testResults
        case userData
        case vitals
        case lastModified
        case patientId
        
    }
}

struct EmergencyContact: Codable, Identifiable {
    var id: String = UUID().uuidString
    var Number: String
    var name: String

    enum CodingKeys: String, CodingKey {
        case Number
        case name
    }
}

struct MedicalRecord: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var url: String
}

struct TestResultF: Codable, Identifiable {
    var id: String = UUID().uuidString
    var dateCreated: Date
    var labTechId: String
    var testType: String
    var url: String
}

struct UserData: Codable {
    var Address: String
    var Dob: String
    var Email: String
    var Name: String
    var Password: String
    var aadharNo: String
    var phoneNo: String
}

struct Vitals: Codable {
    var allergies: [String]
    var bp: [VitalEntry]
    var heartRate: [VitalEntry]
    var height: [VitalEntry]
    var temperature: [VitalEntry]
    var weight: [VitalEntry]
}

struct VitalEntry: Codable, Identifiable {
    var id: String {timestamp.description}
    var timestamp: Date
    var value: String
}
