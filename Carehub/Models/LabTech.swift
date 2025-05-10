//
//  LabTech.swift
//  Carehub
//
//  Created by user@87 on 23/04/25.
//

import SwiftUI
import FirebaseFirestore

struct LabTechnician {
    var Department: String
    var Email: String
    var Name: String
    var Password: String
    var assignedReports: [AssignedReport]
    var phoneNo: String
    var shift: Shift
    var labTechId: String
}

struct AssignedReport{
    var Status: String
    var patientId: String
    var testName: String
}

// Combined data structure to link MedicalTest with Patient1
struct PatientWithTest: Identifiable {
    let id: String // Use the medical test ID as the identifier
    let patient: PatientInfo
    let medicalTest: MedicalTest
}

// Patient1 struct (from patients collection)
struct Patient1: Codable, Identifiable {
    let id: String // Firestore document ID
    let fullName: String
    let generatedID: String
    let age: String
    let previousProblems: String
    let allergies: String
    let medications: String
}

// MedicalTest struct (from medicalTests collection)
struct MedicalTest: Identifiable, Codable {
    let id: String
    let patientId: String
    let testName: String
    let date: String
    let status: String
    let results: String?
    let notes: String?
    let pdfUrl: String? // Added pdfUrl field
    let doc: String?    // Added doc field

    enum CodingKeys: String, CodingKey {
        case id
        case patientId
        case testName
        case date
        case status
        case results
        case notes
        case pdfUrl
        case doc
    }
}


struct PatientInfo: Identifiable, Codable {
    @DocumentID var id: String?
    let patientId: String
    let userData: [String: String]?
    let vitals: Vitals?

    var name: String {
        userData?["Name"] ?? "Patient \(patientId)"
    }

    var age: String {
        guard let dobString = userData?["Dob"],
              let dob = dobString.toDate(format: "dd/MM/yyyy") else {
            return "N/A"
        }
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: dob, to: now)
        return "\(ageComponents.year ?? 0)"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case patientId
        case userData
        case vitals
    }
}

extension String {
    func toDate(format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: self)
    }
}

struct TestResult: Identifiable, Codable {
    let id: String
    let patientId: String
    let testName: String
    let date: String
    let status: String
    let results: String?
    let pdfUrl: String
    let doc: String
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId
        case testName
        case date
        case status
        case results
        case notes
        case pdfUrl
        case doc
    }
    
    init(id: String = UUID().uuidString,
         patientId: String,
         testName: String,
         date: String,
         status: String,
         results: String? = nil,
         notes: String? = nil,
         pdfUrl: String = "",
         doc: String = "") {
        self.id = id
        self.patientId = patientId
        self.testName = testName
        self.date = date
        self.status = status
        self.results = results
        self.notes = notes
        self.pdfUrl = pdfUrl
        self.doc = doc
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        patientId = try container.decode(String.self, forKey: .patientId)
        testName = try container.decode(String.self, forKey: .testName)
        date = try container.decode(String.self, forKey: .date)
        status = try container.decode(String.self, forKey: .status)
        results = try container.decodeIfPresent(String.self, forKey: .results)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        pdfUrl = try container.decodeIfPresent(String.self, forKey: .pdfUrl) ?? ""
        doc = try container.decodeIfPresent(String.self, forKey: .doc) ?? ""
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(patientId, forKey: .patientId)
        try container.encode(testName, forKey: .testName)
        try container.encode(date, forKey: .date)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(results, forKey: .results)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(pdfUrl, forKey: .pdfUrl)
        try container.encode(doc, forKey: .doc)
    }
}

