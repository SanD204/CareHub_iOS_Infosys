import FirebaseFirestore
import Combine
import FirebaseAuth

class StaffManager: ObservableObject {
    @Published var staffList: [Staff] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Computed properties
    var doctors: [Staff] { staffList.filter { $0.role == .doctor } }
    var nurses: [Staff] { staffList.filter { $0.role == .nurse } }
    var labTechs: [Staff] { staffList.filter { $0.role == .labTechnician } }
    var admins: [Staff] { staffList.filter { $0.role == .admin } }
    var accountants: [Staff] { staffList.filter { $0.role == .accountant } }
    
    private let db = Firestore.firestore()
    
    init() {
        fetchAllStaff()
    }
    
    func fetchAllStaff() {
        isLoading = true
        staffList.removeAll()
        errorMessage = nil
        
        let dispatchGroup = DispatchGroup()
        
        // First fetch regular staff (non-doctors)
        let regularStaffCollections = StaffRole.allCases
            .filter { $0 != .doctor }
            .map { $0.collectionName }
        
        fetchRegularStaff(collections: regularStaffCollections, dispatchGroup: dispatchGroup)
        
        // Then fetch doctors separately
        dispatchGroup.enter()
        fetchDoctors {
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            if self.staffList.isEmpty && self.errorMessage == nil {
                self.errorMessage = "No staff data found in any collection"
            }
            print("Total staff fetched: \(self.staffList.count)")
        }
    }

    private func fetchRegularStaff(collections: [String], dispatchGroup: DispatchGroup) {
        for collection in collections {
            dispatchGroup.enter()
            
            db.collection(collection).getDocuments { [weak self] (snapshot, error) in
                guard let self = self else {
                    dispatchGroup.leave()
                    return
                }
                
                defer { dispatchGroup.leave() }
                
                if let error = error {
                    self.handleFetchError(collection: collection, error: error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found in \(collection)")
                    return
                }
                
                do {
                    let staffMembers = try documents.compactMap { document -> Staff? in
                        let data = document.data()
                        return Staff(
                            id: data["id"] as? String ?? document.documentID,
                            fullName: data["fullName"] as? String ?? "Unknown",
                            email: data["email"] as? String ?? "",
                            role: StaffRole(rawValue: data["role"] as? String ?? "") ?? .nurse,
                            department: data["department"] as? String,
                            phoneNumber: data["phoneNumber"] as? String,
                            joinDate: (data["joinDate"] as? Timestamp)?.dateValue(),
                            profileImageURL: data["profileImageURL"] as? String ?? "",
                            shift: (data["shift"] as? [String: Any]).map { dict in
                                Shift(
                                    startTime: (dict["startTime"] as? Timestamp)?.dateValue(),
                                    endTime: (dict["endTime"] as? Timestamp)?.dateValue()
                                )
                            } ?? Shift(startTime: nil, endTime: nil)
                        )
                    }
                    
                    DispatchQueue.main.async {
                        self.staffList.append(contentsOf: staffMembers)
                    }
                } catch {
                    self.handleDecodingError(collection: collection, error: error)
                }
            }
        }
    }

    private func fetchDoctors(completion: @escaping () -> Void) {
        db.collection("doctors").getDocuments { [weak self] (snapshot, error) in
            guard let self = self else {
                completion()
                return
            }
            
            defer { completion() }
            
            if let error = error {
                self.handleFetchError(collection: "doctors", error: error)
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents found in doctors collection")
                return
            }
            
            do {
                let doctors = try documents.compactMap { document -> Staff? in
                    let data = document.data()
                    return Staff(
                        id: data["Doctorid"] as? String ?? document.documentID,
                        fullName: data["Doctor_name"] as? String ?? "Unknown Doctor",
                        email: data["Email"] as? String ?? "",
                        role: .doctor,
                        department: data["Filed_name"] as? String,
                        phoneNumber: data["phoneNo"] as? String,
                        joinDate: (data["createdAt"] as? Timestamp)?.dateValue(),
                        profileImageURL: data["ImageURL"] as? String ?? "",
                        shift: Shift(startTime: nil, endTime: nil) // Doctors might have different shift handling
                    )
                }
                
                DispatchQueue.main.async {
                    self.staffList.append(contentsOf: doctors)
                }
            } catch {
                self.handleDecodingError(collection: "doctors", error: error)
            }
        }
    }

    private func handleFetchError(collection: String, error: Error) {
        self.errorMessage = (self.errorMessage ?? "") + "\nError fetching \(collection): \(error.localizedDescription)"
        print("Error fetching \(collection): \(error.localizedDescription)")
    }

    private func handleDecodingError(collection: String, error: Error) {
        self.errorMessage = (self.errorMessage ?? "") + "\nDecoding error in \(collection): \(error.localizedDescription)"
        print("Decoding error in \(collection): \(error.localizedDescription)")
    }
    
    func addStaff(_ staff: Staff, password: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        AuthManager.shared.createStaff(staff: staff, password: password) { [weak self] (success: Bool) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if success {
                    self.fetchAllStaff() // Refresh the list after adding
                } else {
                    self.errorMessage = AuthManager.shared.errorMessage ?? "Failed to create staff"
                }
                
                self.isLoading = false
                completion(success)
            }
        }
    }
    
    func addDoctor(_ doctor: Doctor, completion: @escaping (Bool) -> Void) {
        isLoading = true
        AuthManager.shared.createDoctor(doctor: doctor) { [weak self] (success: Bool) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if success {
                    self.fetchAllStaff() // Refresh the list after adding
                } else {
                    self.errorMessage = AuthManager.shared.errorMessage ?? "Failed to create doctor"
                }
                
                self.isLoading = false
                completion(success)
            }
        }
    }
    
    func updateStaff(_ updatedStaff: Staff, completion: @escaping (Bool) -> Void) {
        guard let id = updatedStaff.id else {
            errorMessage = "Staff ID missing"
            completion(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try db.collection(updatedStaff.role.collectionName).document(id).setData(from: updatedStaff) { [weak self] error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    self.fetchAllStaff()
                    completion(true)
                }
            }
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            completion(false)
        }
    }
    
    func deleteStaff(_ staff: Staff, completion: @escaping (Bool) -> Void) {
        guard let id = staff.id else {
            errorMessage = "Staff ID missing"
            completion(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        self.db.collection(staff.role.collectionName).document(id).delete { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                completion(false)
            } else {
                self.fetchAllStaff()
                completion(true)
            }
        }
    }
}
