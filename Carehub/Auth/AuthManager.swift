import FirebaseAuth
import FirebaseFirestore
import os.log

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    private let logger = Logger(subsystem: "com.yourapp.Carehub", category: "Auth")
    
    @Published var currentStaffMember: Staff?
    @Published var currentDoctor: Doctor?
    @Published var currentPatient: PatientF?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var navigateToDashboard: Bool = false
    
    private let db = Firestore.firestore()
    
    private init() {
        logger.debug("AuthManager initialized")
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            
            if let user = user {
                self.logger.debug("Auth state changed - user signed in: \(user.uid)")
                self.fetchUserData(uid: user.uid, email: user.email ?? "") { _ in }
            } else {
                self.logger.debug("Auth state changed - user signed out")
                DispatchQueue.main.async {
                    self.currentStaffMember = nil
                    self.currentPatient = nil
                }
            }
        }
    }
    
    func sendEmailVerification(completion: @escaping (Bool, String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            logger.error("No user found for email verification")
            completion(false, "No user found")
            return
        }
        
        user.sendEmailVerification { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.logger.error("Failed to send verification email: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            } else {
                self.logger.debug("Verification email sent to \(user.email ?? "unknown")")
                completion(true, nil)
            }
        }
    }
    
    func checkEmailVerification(completion: @escaping (Bool, String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            logger.error("No user found for email verification check")
            completion(false, "No user found")
            return
        }
        
        user.reload { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.logger.error("Failed to reload user: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            } else {
                let isVerified = user.isEmailVerified
                self.logger.debug("Email verification status for \(user.email ?? "unknown"): \(isVerified)")
                completion(isVerified, isVerified ? nil : "Email not yet verified")
            }
        }
    }
    
    func createStaff(staff: Staff, password: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: staff.email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                completion(false)
                return
            }
            
            guard let user = result?.user else {
                self.isLoading = false
                self.errorMessage = "Staff creation failed"
                completion(false)
                return
            }
            
            let staffData = Staff(
                id: staff.id,
                fullName: staff.fullName,
                email: staff.email,
                role: staff.role,
                department: staff.department,
                phoneNumber: staff.phoneNumber,
                joinDate: staff.joinDate ?? Date(),
                profileImageURL: staff.profileImageURL,
                shift: staff.shift ?? Shift(startTime: nil, endTime: nil)
            )
            
            do {
                try self.db.collection(staff.role.collectionName).document(user.uid).setData(from: staffData) { error in
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                completion(false)
            }
        }
    }
    
    func createDoctor(doctor: Doctor, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: doctor.email ?? "", password: doctor.password ?? "") { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                completion(false)
                return
            }
            
            guard let user = result?.user else {
                self.isLoading = false
                self.errorMessage = "Doctor creation failed"
                completion(false)
                return
            }
            
            let doctorData: [String: Any] = [
                "Doctorid": doctor.id,
                "Filed_name": doctor.department,
                "Doctor_name": doctor.doctor_name,
                "Doctor_experience": doctor.doctor_experience ?? 0,
                "Email": doctor.email ?? "",
                "ImageURL": doctor.imageURL ?? "",
                "Password": doctor.password,
                "consultationFee": doctor.consultationFee ?? 0,
                "license_number": doctor.license_number ?? "",
                "phoneNo": doctor.phoneNo ?? "",
                "doctorsNotes": [] // Initialize empty array for notes
            ]
            
            self.db.collection("doctors").document(user.uid).setData(doctorData) { error in
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    func registerPatient(patient: PatientF, password: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        logger.debug("Registering patient with email: \(patient.userData.Email), password length: \(password.count)")
        
        Auth.auth().createUser(withEmail: patient.userData.Email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                self.logger.error("Registration error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let user = result?.user else {
                self.isLoading = false
                self.errorMessage = "Patient registration failed"
                self.logger.error("Patient registration failed: No user returned")
                completion(false)
                return
            }
            
            self.logger.debug("Firebase Auth user created with UID: \(user.uid)")
            
            // Send email verification
            self.sendEmailVerification { success, errorMessage in
                if !success {
                    self.isLoading = false
                    self.errorMessage = errorMessage ?? "Failed to send verification email"
                    self.logger.error("Failed to send verification email: \(errorMessage ?? "Unknown error")")
                    completion(false)
                    return
                }
                
                // Store patient data after sending verification email
                let patientData = patient
                do {
                    try self.db.collection("patients").document(user.uid).setData(from: patientData) { error in
                        self.isLoading = false
                        
                        if let error = error {
                            self.errorMessage = error.localizedDescription
                            self.logger.error("Firestore write error: \(error.localizedDescription)")
                            completion(false)
                        } else {
                            self.logger.debug("Patient data stored in Firestore for UID: \(user.uid)")
                            completion(true)
                        }
                    }
                } catch {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.logger.error("Encoding error: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
    
    func login(email: String, password: String, role: LoginView.Role, completion: @escaping (Bool) -> Void) {
        logger.debug("Attempting login for email: \(email), password length: \(password.count), role: \(role == .patient ? "patient" : "staff")")
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleLoginError(error)
                completion(false)
                return
            }
            
            guard let user = result?.user else {
                self.handleLoginError(nil)
                completion(false)
                return
            }
            
            // Check email verification only for patients
            if role == .patient && !user.isEmailVerified {
                self.isLoading = false
                self.errorMessage = "Please verify your email before logging in."
                self.logger.error("Login failed: Email not verified for user \(user.uid)")
                completion(false)
                return
            }
            
            self.logger.debug("Login successful for user: \(user.uid)")
            self.fetchUserData(uid: user.uid, email: email) { success in
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(success)
                }
            }
        }
    }
    
    private func handleLoginError(_ error: Error?) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = error?.localizedDescription ?? "Login failed"
            self.logger.error("Login error: \(self.errorMessage ?? "Unknown error")")
        }
    }
    
    func fetchUserData(uid: String, email: String, completion: @escaping (Bool) -> Void) {
        logger.debug("Fetching user data for uid: \(uid)")
        isLoading = true
        
        // Add a timeout to prevent infinite loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.isLoading {
                self.logger.error("Fetch user data timed out for uid: \(uid)")
                self.isLoading = false
                self.errorMessage = "Failed to load user data: Timeout"
                completion(false)
            }
        }
        
        // Check admin collection first
        db.collection("admins").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if self.isLoading == false { return } // If timed out, stop processing
            
            if let error = error {
                self.logger.error("Admin check error: \(error.localizedDescription)")
                self.checkOtherStaffCollections(uid: uid, completion: completion)
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                do {
                    let admin = try snapshot.data(as: Staff.self)
                    DispatchQueue.main.async {
                        self.currentStaffMember = admin
                        self.currentPatient = nil
                        self.isLoading = false
                        self.logger.debug("Admin data loaded successfully: \(admin.fullName)")
                        completion(true)
                    }
                } catch {
                    self.handleDecodingError(error, collection: "admins")
                    completion(false)
                }
                return
            }
            
            self.checkOtherStaffCollections(uid: uid, completion: completion)
        }
    }
    
    private func checkOtherStaffCollections(uid: String, completion: @escaping (Bool) -> Void) {
        let roles = StaffRole.allCases.filter { $0 != .admin }
        var found = false
        let dispatchGroup = DispatchGroup()

        for role in roles {
            let collection = role.collectionName
            dispatchGroup.enter()
            logger.debug("Checking collection: \(collection)")
            
            db.collection(collection).document(uid).getDocument { [weak self] snapshot, error in
                defer { dispatchGroup.leave() }
                guard let self = self else { return }

                if self.isLoading == false || found { return }

                if let error = error {
                    self.logger.error("Error checking \(collection): \(error.localizedDescription)")
                    return
                }

                if let snapshot = snapshot, snapshot.exists {
                    found = true
                    do {
                        // Role-specific decoding
                        if role == .doctor {
                            let doctor = try snapshot.data(as: Doctor.self)
                            DispatchQueue.main.async {
                                self.currentDoctor = doctor
                                self.currentStaffMember = nil
                                self.currentPatient = nil
                                self.isLoading = false
                                self.logger.debug("Doctor data loaded from \(collection): \(doctor.doctor_name)")
                                completion(true)
                            }
                        } else {
                            let staff = try snapshot.data(as: Staff.self)
                            DispatchQueue.main.async {
                                self.currentStaffMember = staff
                                self.currentDoctor = nil
                                self.currentPatient = nil
                                self.isLoading = false
                                self.logger.debug("Staff data loaded from \(collection): \(staff.fullName)")
                                completion(true)
                            }
                        }
                    } catch {
                        self.handleDecodingError(error, collection: collection)
                        completion(false)
                    }
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            if !found && self.isLoading {
                self.checkPatientCollection(uid: uid, completion: completion)
            }
        }
    }

    
    private func checkPatientCollection(uid: String, completion: @escaping (Bool) -> Void) {
        db.collection("patients").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if self.isLoading == false { return } // If timed out, stop processing
            
            self.isLoading = false
            
            if let error = error {
                self.logger.error("Patient check error: \(error.localizedDescription)")
                self.errorMessage = "No user data found"
                completion(false)
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                self.logger.error("No user data found in any collection for uid: \(uid)")
                self.errorMessage = "No user data found"
                completion(false)
                return
            }
            
            do {
                let patient = try snapshot.data(as: PatientF.self)
                DispatchQueue.main.async {
                    self.currentPatient = patient
                    self.currentStaffMember = nil
                    self.logger.debug("Patient data loaded: \(patient.userData.Name)")
                    completion(true)
                }
            } catch {
                self.handleDecodingError(error, collection: "patients")
                completion(false)
            }
        }
    }
    
    private func handleDecodingError(_ error: Error, collection: String) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = "Failed to decode \(collection) data: \(error.localizedDescription)"
            self.logger.error("Decoding error in \(collection): \(error.localizedDescription)")
        }
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
            currentStaffMember = nil
            currentPatient = nil
            navigateToDashboard = false
            logger.debug("User logged out successfully")
        } catch {
            logger.error("Logout failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}
