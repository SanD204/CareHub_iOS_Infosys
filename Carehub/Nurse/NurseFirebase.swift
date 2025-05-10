import Firebase
import Foundation

class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    // MARK: - Patient Methods

    func patientExists(patientID: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        db.collection("patients").document(patientID).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(snapshot?.exists ?? false))
        }
    }
    
    func fetchPatientName(patientID: String, completion: @escaping (Result<String, Error>) -> Void) {
            db.collection("patients").whereField("patientId", isEqualTo: patientID).getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let document = snapshot?.documents.first,
                      let userData = document.data()["userData"] as? [String: Any],
                      let name = userData["Name"] as? String else {
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Name not found for patientID: \(patientID)"])))
                    return
                }
                
                completion(.success(name))
            }
        }
    
    func savePatientVitals(patientID: String, vitals: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        let timestamp = Timestamp(date: Date())
        
        db.collection("patients")
            .whereField("patientId", isEqualTo: patientID)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    completion(.failure(NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Patient not found"])))
                    return
                }
                
                let patientRef = document.reference
                let currentVitals = document.data()["vitals"] as? [String: Any] ?? [:]
                let vitalTypes = ["bp", "weight", "height", "heartRate", "temperature"]
                
                var updatedVitals: [String: Any] = [:]
                
                for type in vitalTypes {
                    if let value = vitals[type] {
                        let valueStr = "\(value)"
                        if !valueStr.trimmingCharacters(in: .whitespaces).isEmpty {
                            var history = currentVitals[type] as? [[String: Any]] ?? []
                            history.append([
                                "value": value,
                                "timestamp": timestamp
                            ])
                            updatedVitals[type] = history
                        }
                    }
                }
                
                // Handle allergies (stored inside vitals)
                if let allergyString = vitals["allergies"] as? String {
                    let allergyArray = allergyString
                        .components(separatedBy: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    
                    if !allergyArray.isEmpty {
                        updatedVitals["allergies"] = allergyArray
                    }
                }
                
                guard !updatedVitals.isEmpty else {
                    completion(.success(()))
                    return
                }
                
                let updates: [String: Any] = [
                    "vitals": updatedVitals,
                    "lastModified": timestamp
                ]
                
                patientRef.setData(updates, merge: true) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
    }

    func fetchPatientVitals(patientID: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        db.collection("patients")
            .whereField("patientId", isEqualTo: patientID)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let document = snapshot?.documents.first,
                      let vitals = document.data()["vitals"] as? [String: Any] else {
                    completion(.success([:]))
                    return
                }

                var result: [String: Any] = [:]
                let vitalTypes = ["bp", "weight", "height", "heartRate", "temperature"]
                
                for type in vitalTypes {
                    if let history = vitals[type] as? [[String: Any]], let latest = history.last {
                        result[type] = latest["value"] ?? ""
                        
                        let transformedHistory: [[String: Any]] = history.compactMap { entry in
                            guard let value = entry["value"],
                                  let timestamp = entry["timestamp"] as? Timestamp else {
                                return nil
                            }
                            return [
                                "value": value,
                                "timestamp": timestamp.dateValue()
                            ]
                        }
                        result["\(type)History"] = transformedHistory
                    }
                }
                
                if let allergies = vitals["allergies"] as? [String] {
                    result["allergies"] = allergies.joined(separator: ", ")
                }

                completion(.success(result))
            }
    }

    func fetchVitalTrends(patientID: String, vitalType: String, completion: @escaping (Result<[(String, Date)], Error>) -> Void) {
        db.collection("patients").document(patientID).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data(),
                  let vitals = data["vitals"] as? [String: Any],
                  let history = vitals[vitalType] as? [[String: Any]] else {
                completion(.success([]))
                return
            }
            
            let trendData = history.compactMap { entry -> (String, Date)? in
                guard let value = entry["value"] as? String,
                      let timestamp = entry["timestamp"] as? Timestamp else {
                    return nil
                }
                return (value, timestamp.dateValue())
            }
            
            completion(.success(trendData))
        }
    }
    
    func fetchNurse(byId nurseId: String, completion: @escaping (Result<Nurse, Error>) -> Void) {
        db.collection("nurses")
            .whereField("id", isEqualTo: nurseId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let document = snapshot?.documents.first else {
                    completion(.failure(NSError(
                        domain: "FirebaseService",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "Nurse not found."]
                    )))
                    return
                }

                guard let nurse = Nurse(from: document.data()) else {
                    completion(.failure(NSError(
                        domain: "FirebaseService",
                        code: 422,
                        userInfo: [NSLocalizedDescriptionKey: "Nurse data is invalid."]
                    )))
                    return
                }

                completion(.success(nurse))
            }
    }



    func fetchAppointmentsForToday(completion: @escaping (Result<[Appointment], Error>) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now

        db.collection("appointments")
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: endOfDay))
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }

                let appointments: [Appointment] = documents.compactMap { doc in
                    let data = doc.data()
                    let id = doc.documentID
                    let apptId = data["apptId"] as? String ?? ""
                    let patientId = data["patientId"] as? String ?? ""
                    let description = data["description"] as? String ?? ""
                    let docId = data["docId"] as? String ?? ""
                    let status = data["status"] as? String ?? ""
                    let billingStatus = data["billingStatus"] as? String ?? ""
                    let amount = data["amount"] as? Double
                    let date = (data["date"] as? Timestamp)?.dateValue()
                    let doctorsNotes = data["doctorsNotes"] as? String
                    let prescriptionId = data["prescriptionId"] as? String
                    let followUpRequired = data["followUpRequired"] as? Bool
                    let followUpDate = (data["followUpDate"] as? Timestamp)?.dateValue()

                    return Appointment(
                        id: id,
                        apptId: apptId,
                        patientId: patientId,
                        description: description,
                        docId: docId,
                        status: status,
                        billingStatus: billingStatus,
                        amount: amount,
                        date: date,
                        doctorsNotes: doctorsNotes,
                        prescriptionId: prescriptionId,
                        followUpRequired: followUpRequired,
                        followUpDate: followUpDate
                    )
                }

                completion(.success(appointments))
            }
    }
    
    func fetchDoctorName(docId: String, completion: @escaping (Result<String, Error>) -> Void) {
        db.collection("doctors")
            .whereField("Doctorid", isEqualTo: docId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                } else if let documents = snapshot?.documents, let document = documents.first,
                          let name = document.data()["Doctor_name"] as? String {
                    completion(.success(name))
                } else {
                    completion(.failure(NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Doctor name not found"])))
                }
            }
    }
}

class NurseViewModel: ObservableObject {
    @Published var nurse: Nurse?
    @Published var isLoading = false
    @Published var error: Error?

    func fetchNurse(byNurseId nurseId: String) {
        isLoading = true
        error = nil

        FirebaseService.shared.fetchNurse(byId: nurseId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let nurse):
                    self.nurse = nurse
                case .failure(let err):
                    self.error = err
                }
            }
        }
    }
}

class NurseHomeViewModel: ObservableObject {
    @Published var allAppointments: [Appointment] = []
    @Published var filteredAppointments: [Appointment] = []
    @Published var searchText: String = ""
    
    init() {
        fetchAppointments()
    }

    func fetchAppointments() {
        FirebaseService.shared.fetchAppointmentsForToday { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let appointments):
                    // Filter out cancelled appointments
                    let activeAppointments = appointments.filter { $0.status.lowercased() != "cancelled" }
                    self.allAppointments = activeAppointments
                    self.filterAppointments()
                case .failure(let error):
                    print("Error fetching appointments: \(error)")
                }
            }
        }
    }

    func filterAppointments() {
        if searchText.isEmpty {
            filteredAppointments = allAppointments
        } else {
            let lowercased = searchText.lowercased()
            
            // We'll filter in two steps:
            // 1. First filter by IDs that might match (fast)
            let potentiallyMatching = allAppointments.filter { appt in
                appt.patientId.lowercased().contains(lowercased) ||
                appt.docId.lowercased().contains(lowercased)
            }
            
            // 2. Then check names for these filtered appointments
            filterAppointmentsByName(potentiallyMatching, searchTerm: lowercased)
        }
    }
    
    private func filterAppointmentsByName(_ appointments: [Appointment], searchTerm: String) {
        var matchingAppointments: [Appointment] = []
        let group = DispatchGroup()
        
        for appt in appointments {
            group.enter()
            
            // Check both patient and doctor names
            var patientMatches = false
            var doctorMatches = false
            
            // Check patient name
            FirebaseService.shared.fetchPatientName(patientID: appt.patientId) { result in
                if case .success(let name) = result, name.lowercased().contains(searchTerm) {
                    patientMatches = true
                }
                
                // Check doctor name
                FirebaseService.shared.fetchDoctorName(docId: appt.docId) { result in
                    if case .success(let name) = result, name.lowercased().contains(searchTerm) {
                        doctorMatches = true
                    }
                    
                    if patientMatches || doctorMatches {
                        DispatchQueue.main.async {
                            matchingAppointments.append(appt)
                        }
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            self.filteredAppointments = matchingAppointments
        }
    }
    
    func getPatientName(for patientId: String, completion: @escaping (String) -> Void) {
            FirebaseService.shared.fetchPatientName(patientID: patientId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let name):
                        completion(name)
                    case .failure(_):
                        completion("Unknown Patient")
                    }
                }
            }
        }
        
        func getDoctorName(for docId: String, completion: @escaping (String) -> Void) {
            FirebaseService.shared.fetchDoctorName(docId: docId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let name):
                        completion(name)
                    case .failure(_):
                        completion("Unknown Doctor")
                    }
                }
            }
        }
}
