//
//  ChatViewModel.swift
//  Carehub
//
//  Created by Yash Gupta on 08/05/25.
//

import SwiftUI
import FirebaseFirestore


@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    private var lastSuggestedDepartment: String?
    private var lastSymptoms: [String] = []
    
    private let geminiService = GeminiService.shared
    private let db = Firestore.firestore()
    
    init() {
        addWelcomeMessage()
    }
    
    private func addWelcomeMessage() {
        messages.append(ChatMessage(
            id: UUID(),
            role: .doctor,
            content: "Hi there! I'm your Health Assistant, here to help you find the right care. 😊 Just tell me how you're feeling—like 'I have a fever and cough'—and I'll guide you to the right department. What’s going on with you today?",
            timestamp: Date()
        ))
    }
    
    func sendMessage() async {
        guard !inputText.isEmpty else { return }
        
        let userMessage = ChatMessage(
            id: UUID(),
            role: .patient,
            content: inputText,
            timestamp: Date()
        )
        messages.append(userMessage)
        isLoading = true
        let tempInput = inputText
        inputText = ""
        
        do {
            let lowercasedInput = tempInput.lowercased()
            
            // Check if user is asking about symptoms (e.g., "What symptoms does fever have?")
            if lowercasedInput.contains("what symptoms") || lowercasedInput.contains("symptoms of") || lowercasedInput.contains("symptoms does") {
                if lowercasedInput.contains("fever") {
                    messages.append(ChatMessage(
                        id: UUID(),
                        role: .doctor,
                        content: "A fever often comes with symptoms like chills, sweating, headache, muscle aches, fatigue, or a high body temperature (above 100.4°F or 38°C). It might be caused by an infection or other conditions. Would you like to tell me more about how you're feeling, or should I suggest a department for you?",
                        timestamp: Date()
                    ))
                } else {
                    messages.append(ChatMessage(
                        id: UUID(),
                        role: .doctor,
                        content: "Could you specify which condition or symptom you're asking about? For example, 'What symptoms does fever have?' I'll be happy to help!",
                        timestamp: Date()
                    ))
                }
            }
            // Check if user is asking for a doctor or wants to proceed
            else if lowercasedInput.contains("doctor") || lowercasedInput.contains("who should i see") || lowercasedInput.contains("recommend") || lowercasedInput.contains("suggest") || lowercasedInput.contains("find") || lowercasedInput.contains("yes") {
                guard let department = lastSuggestedDepartment else {
                    messages.append(ChatMessage(
                        id: UUID(),
                        role: .doctor,
                        content: "I need to know your symptoms first to suggest a department. Could you please describe how you're feeling?",
                        timestamp: Date()
                    ))
                    isLoading = false
                    return
                }
                
                let doctors = try await fetchDoctors(for: department)
                if doctors.isEmpty {
                    messages.append(ChatMessage(
                        id: UUID(),
                        role: .doctor,
                        content: "I couldn't find any doctors in the \(department) department right now. Please consult a healthcare professional for assistance.",
                        timestamp: Date(),
                        isDoctorList: true
                    ))
                } else {
                    messages.append(ChatMessage(
                        id: UUID(),
                        role: .doctor,
                        content: "",
                        timestamp: Date(),
                        doctors: doctors,
                        isDoctorList: true
                    ))
                }
            }
            // Check if user wants more info about their symptoms
            else if lowercasedInput.contains("tell me more") || lowercasedInput.contains("more about") || lowercasedInput.contains("explain") {
                if lastSymptoms.contains("fever") {
                    messages.append(ChatMessage(
                        id: UUID(),
                        role: .doctor,
                        content: "A fever often indicates your body is fighting an infection, like a cold or flu, but it can also be due to other causes like inflammation. You might feel chills, sweat a lot, or have a headache. Would you like to share any other symptoms, or should I suggest a department for you?",
                        timestamp: Date()
                    ))
                } else {
                    messages.append(ChatMessage(
                        id: UUID(),
                        role: .doctor,
                        content: "I’d be happy to explain more! Could you tell me which symptom or condition you’d like more information about?",
                        timestamp: Date()
                    ))
                }
            }
            // Handle symptom input and suggest a department
            else {
                // Track symptoms mentioned by the user
                lastSymptoms = extractSymptoms(from: lowercasedInput)
                
                let response = try await geminiService.sendMessage(tempInput)
                let department = extractDepartment(from: response, userInput: lowercasedInput)
                lastSuggestedDepartment = department
                
                messages.append(ChatMessage(
                    id: UUID(),
                    role: .doctor,
                    content: "Given your symptoms, I suggest consulting the \(department) department.\n\(response)\nWould you like me to find a doctor in this department, or do you want to know more about your symptoms?",
                    timestamp: Date(),
                    department: department,
                    isDepartment: true
                ))
            }
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    private func extractSymptoms(from input: String) -> [String] {
        var symptoms: [String] = []
        let lowercasedInput = input.lowercased()
        if lowercasedInput.contains("fever") { symptoms.append("fever") }
        if lowercasedInput.contains("cough") { symptoms.append("cough") }
        if lowercasedInput.contains("headache") { symptoms.append("headache") }
        if lowercasedInput.contains("dizziness") { symptoms.append("dizziness") }
        if lowercasedInput.contains("sore throat") { symptoms.append("sore throat") }
        return symptoms
    }
    
    private func extractDepartment(from response: String, userInput: String) -> String {
        let lowercasedResponse = response.lowercased()
        let lowercasedInput = userInput.lowercased()
        
        if (lowercasedResponse.contains("fever") || lowercasedInput.contains("fever")) && !lowercasedResponse.contains("ent") && !lowercasedResponse.contains("ear") && !lowercasedResponse.contains("throat") && !lowercasedInput.contains("ear") && !lowercasedInput.contains("throat") {
            return "General Practitioner"
        } else if lowercasedResponse.contains("cardiologist") || lowercasedResponse.contains("cardiology") || lowercasedInput.contains("heart") {
            return "Cardiology"
        } else if lowercasedResponse.contains("orthopedist") || lowercasedResponse.contains("orthopedics") || lowercasedResponse.contains("bone") || lowercasedResponse.contains("joint") || lowercasedInput.contains("bone") || lowercasedInput.contains("joint") {
            return "Orthopedics"
        } else if lowercasedResponse.contains("neurologist") || lowercasedResponse.contains("neurology") || lowercasedResponse.contains("headache") || lowercasedResponse.contains("dizziness") || lowercasedInput.contains("headache") || lowercasedInput.contains("dizziness") {
            return "Neurology"
        } else if lowercasedResponse.contains("gynecologist") || lowercasedResponse.contains("gynecology") || lowercasedInput.contains("gynecology") {
            return "Gynecology"
        } else if lowercasedResponse.contains("surgeon") || lowercasedResponse.contains("surgery") || lowercasedInput.contains("surgery") {
            return "Surgery"
        } else if lowercasedResponse.contains("dermatologist") || lowercasedResponse.contains("dermatology") || lowercasedResponse.contains("skin") || lowercasedInput.contains("skin") {
            return "Dermatology"
        } else if lowercasedResponse.contains("endocrinologist") || lowercasedResponse.contains("endocrinology") || lowercasedResponse.contains("diabetes") || lowercasedInput.contains("diabetes") {
            return "Endocrinology"
        } else if lowercasedResponse.contains("ent") || lowercasedResponse.contains("ear") || lowercasedResponse.contains("throat") || lowercasedInput.contains("ear") || lowercasedInput.contains("throat") {
            return "ENT"
        } else if lowercasedResponse.contains("oncologist") || lowercasedResponse.contains("oncology") || lowercasedResponse.contains("cancer") || lowercasedInput.contains("cancer") {
            return "Oncology"
        } else if lowercasedResponse.contains("psychiatrist") || lowercasedResponse.contains("psychiatry") || lowercasedResponse.contains("mental") || lowercasedInput.contains("mental") {
            return "Psychiatry"
        } else if lowercasedResponse.contains("urologist") || lowercasedResponse.contains("urology") || lowercasedInput.contains("urology") {
            return "Urology"
        } else if lowercasedResponse.contains("pediatrician") || lowercasedResponse.contains("pediatrics") || lowercasedResponse.contains("child") || lowercasedInput.contains("child") {
            return "Pediatrics"
        } else {
            return "General Practitioner"
        }
    }
    
    private func fetchDoctors(for department: String) async throws -> [Doctor2] {
        let snapshot = try await db.collection("doctors")
            .whereField("Filed_name", isEqualTo: department)
            .getDocuments()
        
        let doctors = try snapshot.documents.compactMap { document in
            try document.data(as: Doctor2.self)
        }
        
        print("Fetched doctors for \(department): \(doctors.count)")
        return doctors
    }
    
    private func handleError(_ error: Error) {
        let errorMessage = "Error: \(error.localizedDescription)"
        messages.append(ChatMessage(
            id: UUID(),
            role: .doctor,
            content: "⚠️ \(errorMessage)",
            timestamp: Date()
        ))
        self.showError = true
        self.errorMessage = errorMessage
        print("❌ Error: \(error)")
    }
}

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    let department: String?
    let doctors: [Doctor2]?
    let isDepartment: Bool
    let isDoctorList: Bool
    
    init(id: UUID, role: MessageRole, content: String, timestamp: Date, department: String? = nil, doctors: [Doctor2]? = nil, isDepartment: Bool = false, isDoctorList: Bool = false) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.department = department
        self.doctors = doctors
        self.isDepartment = isDepartment
        self.isDoctorList = isDoctorList
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id &&
               lhs.role == rhs.role &&
               lhs.content == rhs.content &&
               lhs.timestamp == rhs.timestamp &&
               lhs.department == rhs.department &&
               lhs.doctors == rhs.doctors &&
               lhs.isDepartment == rhs.isDepartment &&
               lhs.isDoctorList == rhs.isDoctorList
    }
    
    enum MessageRole {
        case patient
        case doctor
    }
}

struct Doctor2: Identifiable, Codable, Equatable {
    let id: String
    let department: String
    let doctor_name: String
    let doctor_experience: Int?
    let email: String?
    let imageURL: String?
    let password: String?
    let consultationFee: Int?
    let license_number: String?
    let phoneNo: String?
    var doctorsNotes: [DoctorNote2]?

    enum CodingKeys: String, CodingKey {
        case id = "Doctorid"
        case department = "Filed_name"
        case doctor_name = "Doctor_name"
        case doctor_experience = "Doctor_experience"
        case email = "Email"
        case imageURL = "ImageURL"
        case password = "Password"
        case consultationFee = "consultationFee"
        case license_number = "license_number"
        case phoneNo = "phoneNo"
    }
    
    static func == (lhs: Doctor2, rhs: Doctor2) -> Bool {
        return lhs.id == rhs.id &&
               lhs.department == rhs.department &&
               lhs.doctor_name == rhs.doctor_name &&
               lhs.doctor_experience == rhs.doctor_experience &&
               lhs.email == rhs.email &&
               lhs.imageURL == rhs.imageURL &&
               lhs.password == rhs.password &&
               lhs.consultationFee == rhs.consultationFee &&
               lhs.license_number == rhs.license_number &&
               lhs.phoneNo == rhs.phoneNo &&
               lhs.doctorsNotes == rhs.doctorsNotes
    }
}

struct DoctorNote2: Codable, Equatable {
    let note: String
    
    static func == (lhs: DoctorNote2, rhs: DoctorNote2) -> Bool {
        return lhs.note == rhs.note
    }
}
