import Foundation
import FirebaseFirestore

enum StaffRole: String, CaseIterable, Codable, Identifiable {
    case doctor = "Doctor"
    case nurse = "Nurse"
    case labTechnician = "Lab Technician"
    case admin = "Admin"
    case accountant = "Accountant"
    
    var id: String { self.rawValue }
    
    var collectionName: String {
        switch self {
        case .doctor: return "doctors"
        case .nurse: return "nurses"
        case .labTechnician: return "labTechs"
        case .admin: return "admins"
        case .accountant: return "accountants"
        }
    }
}

struct Staff: Identifiable, Codable {
    var id: String?  // Firestore-managed ID
    var fullName: String
    var email: String
    var role: StaffRole
    var department: String?
    var phoneNumber: String?
    var joinDate: Date?
    var profileImageURL: String?  // Re-added to match Firestore and existing code
    var shift: Shift?
    
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName
        case email
        case role
        case department
        case phoneNumber
        case joinDate
        case profileImageURL
        case shift
    }
    
    // Custom initializer
    init(id: String? = nil,
         fullName: String,
         email: String,
         role: StaffRole,
         department: String? = nil,
         phoneNumber: String? = nil,
         joinDate: Date? = nil,
         profileImageURL: String? = nil,
         shift : Shift ){
        self.id = id
        self.fullName = fullName
        self.email = email
        self.role = role
        self.department = department
        self.phoneNumber = phoneNumber
        self.joinDate = joinDate
        self.profileImageURL = profileImageURL
        self.shift = shift
    }
}

struct Shift: Codable{
    var startTime: Date?
    var endTime: Date?
}
