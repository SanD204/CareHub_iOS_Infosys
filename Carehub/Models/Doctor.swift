import Foundation
import FirebaseFirestore

struct Doctor: Identifiable, Codable {
    let id: String
    let department: String
    let doctor_name: String
    let doctor_experience: Int?
    let email: String?
    let imageURL: String?
    var password: String?
    let consultationFee: Int?
    let license_number: String?
    let phoneNo: String?
    var doctorsNotes: [DoctorsNote]? // Added to store notes from appointments

    enum CodingKeys: String, CodingKey {
        case id = "Doctorid" // Matches Firestore field
        case department = "Filed_name" // Correcting typo, assuming it should be Department
        case doctor_name = "Doctor_name"
        case doctor_experience = "Doctor_experience"
        case email = "Email"
        case imageURL = "ImageURL"
        case password = "Password"
        case consultationFee = "consultationFee"
        case license_number = "license_number"
        case phoneNo = "phoneNo"
        // doctorsNotes is not directly in Firestore, will be populated from appointments
    }
}

class DoctorData {
    static let db = Firestore.firestore()
    static var specialties: [String] = []
    static var doctors: [String: [Doctor]] = [:]
    
    static func fetchDoctors(completion: @escaping () -> Void) {
        db.collection("doctors").getDocuments(source: .default) { (querySnapshot, error) in
            if let error = error {
                print("Error fetching doctors: \(error.localizedDescription)")
                completion()
                return
            }
            
            var tempSpecialties: Set<String> = []
            var tempDoctors: [String: [Doctor]] = [:]
            
            let dispatchGroup = DispatchGroup()
            
            for document in querySnapshot?.documents ?? [] {
                dispatchGroup.enter()
                print("Raw document data: \(document.data())")
                do {
                    let doctor = try document.data(as: Doctor.self)
                    print("Successfully decoded doctor: \(doctor.id) - \(doctor.doctor_name) (\(doctor.department))")
                    tempSpecialties.insert(doctor.department)
                    
                    // Fetch notes for this doctor from appointments
                    fetchDoctorNotes(forDoctorId: doctor.id) { notes in
                        var doctorWithNotes = doctor
                        doctorWithNotes.doctorsNotes = notes.isEmpty ? nil : notes
                        
                        if var departmentDoctors = tempDoctors[doctor.department] {
                            departmentDoctors.append(doctorWithNotes)
                            tempDoctors[doctor.department] = departmentDoctors
                        } else {
                            tempDoctors[doctor.department] = [doctorWithNotes]
                        }
                        dispatchGroup.leave()
                    }
                } catch {
                    print("Error decoding doctor from \(document.documentID): \(error.localizedDescription)")
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                specialties = Array(tempSpecialties).sorted()
                doctors = tempDoctors
                print("Specialties: \(specialties)")
                print("Doctors by specialty: \(doctors.mapValues { $0.map { $0.doctor_name } })")
                completion()
            }
        }
    }
    
    static func fetchDoctorNotes(forDoctorId doctorId: String, completion: @escaping ([DoctorsNote]) -> Void) {
        db.collection("appointments")
            .whereField("docId", isEqualTo: doctorId)
            .getDocuments(source: .default) { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching appointments for doctor \(doctorId): \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                let notes = querySnapshot?.documents.compactMap { document -> DoctorsNote? in
                    guard let data = document.data() as [String: Any]?,
                          let note = data["doctorsNotes"] as? String,
                          !note.isEmpty else {
                        return nil
                    }
                    return DoctorsNote(
                        appointmentID: document.documentID,
                        note: note,
                        patientID: data["patientId"] as? String ?? ""
                    )
                } ?? []
                completion(notes)
            }
    }
}
