import Firebase
import FirebaseFirestore

struct DatabaseInitializer {
    static let db = Firestore.firestore()
    
    static func initializeDatabase(completion: @escaping (Bool, Error?) -> Void) {
        let batch = db.batch()

        let patientId = UUID().uuidString
        let patientRef = db.collection("patients").document(patientId)
        let patientData: [String: Any] = [
            "patientId": patientId,
            "userData": [
                "Name": "John Doe",
                "Email": "john.doe@example.com",
                "Dob": "1985-05-15",
                "Password": "hashed_password_placeholder",
                "phoneNo": "+1234567890",
                "Address": "123 Main St, Cityville",
                "aadharNo": "1234-5678-9012"
            ],
            "emergencyContact": [
                ["name": "Jane Doe", "Number": "+1987654321"]
            ],
            "medicalRecords": [
                ["name": "Annual Physical", "url": "https://storage.example.com/records/phy2023.pdf"]
            ],
            "testResults": [
                [
                    "testType": "Blood Test",
                    "dateCreated": Timestamp(date: Date()),
                    "labTechId": "LT001",
                    "url": "https://storage.example.com/tests/blood2023.pdf"
                ]
            ],
            "Vitals": [
                "bp": "120/80",
                "weight": 75,
                "height": 175,
                "allergy": "Penicillin",
                "heartRate": 72,
                "temperature": 98.6
            ]
        ]
        batch.setData(patientData, forDocument: patientRef)
        
        // 2. Appointments Collection
        let appointmentRef = db.collection("appointments").document("APT001")
        let appointmentData: [String: Any] = [
            "apptId": "APT001",
            "patientId": patientId,
            "docId": "DOC001",
            "Date": Timestamp(date: Date()),
            "Description": "Annual Checkup",
            "Status": "completed",
            "doctorsNotes": "Patient in good health, recommended annual blood work",
            "billingStatus": "paid",
            "prescriptionId": "RX001",
            "followUpRequired": true,
            "followUpDate": Timestamp(date: Calendar.current.date(byAdding: .month, value: 6, to: Date())!)
        ]
        batch.setData(appointmentData, forDocument: appointmentRef)
        
        // 3. Chats Collection
        let chatRef = db.collection("chats").document("CHAT001")
        let chatData: [String: Any] = [
            "Chatid": "CHAT001",
            "Messages": [
                [
                    "messageld": "MSG001",
                    "Id": "MSG001",
                    "recieverId": patientId,
                    "senderId": "DOC001",
                    "Text": "Hello, how are you feeling today?",
                    "timestamp": Timestamp(date: Date())
                ]
            ]
        ]
        batch.setData(chatData, forDocument: chatRef)
        
        // 4. Billing Collection
        let billingRef = db.collection("billing").document("BIL001")
        let billingData: [String: Any] = [
            "Billingid": "BIL001",
            "patientId": patientId,
            "doctorId": "DOC001",
            "appointmentId": "APT001",
            "date": Timestamp(date: Date()),
            "paymentMode": "Credit Card",
            "Bills": [
                ["itemName": "Consultation", "Fee": 150, "isPaid": true]
            ],
            "paidAmt": 150,
            "insuranceAmt": 0,
            "billingStatus": "paid"
        ]
        batch.setData(billingData, forDocument: billingRef)
        
        // 5. Admins Collection
        let adminRef = db.collection("admins").document("ADM001")
        let adminData: [String: Any] = [
            "adminId": "ADM001",
            "Name": "Admin User",
            "Password": "hashed_admin_password",
            "Email": "admin@hospital.com",
            "phoneNo": "+1000000000",
            "lastLogin": Timestamp(date: Date())
        ]
        batch.setData(adminData, forDocument: adminRef)
        
        // 6. Nurses Collection
        let nurseRef = db.collection("nurses").document("NUR001")
        let nurseData: [String: Any] = [
            "nurseld": "NUR001",
            "Name": "Emma Johnson",
            "Email": "emma.johnson@hospital.com",
            "phoneNo": "+1555666777",
            "Password": "hashed_nurse_password",
            "Shift": ["startTime": "07:00", "endTime": "19:00"],
            "createdAt": Timestamp(date: Date()),
            "Department": "Emergency"
        ]
        batch.setData(nurseData, forDocument: nurseRef)
        
        // 7. LabTechs Collection
        let labTechRef = db.collection("labTechs").document("LT001")
        let labTechData: [String: Any] = [
            "labTechId": "LT001",
            "Name": "Michael Chen",
            "Email": "michael.chen@hospital.com",
            "phoneNo": "+1888999000",
            "Password": "hashed_labtech_password",
            "Department": "Pathology",
            "shift": ["startTime": "09:00", "endTime": "18:00"],
            "assignedReports": [
                ["patientId": patientId, "testName": "Complete Blood Count", "Status": "completed"]
            ]
        ]
        batch.setData(labTechData, forDocument: labTechRef)
        
        // 8. Accountants Collection
        let accountantRef = db.collection("accountants").document("ACC001")
        let accountantData: [String: Any] = [
            "accountantId": "ACC001",
            "Name": "David Wilson",
            "Email": "david.wilson@hospital.com",
            "phoneNo": "+1222333444",
            "Password": "hashed_accountant_password",
            "Shift": ["startTime": "08:00", "endTime": "17:00"],
            "createdAt": Timestamp(date: Date())
        ]
        batch.setData(accountantData, forDocument: accountantRef)
        
        // 9. Prescriptions Collection
        let prescriptionRef = db.collection("prescriptions").document("RX001")
        let prescriptionData: [String: Any] = [
            "prescriptionId": "RX001",
            "appointmentId": "APT001",
            "patientId": patientId,
            "doctorId": "DOC001",
            "createdAt": Timestamp(date: Date()),
            "Medicines": [
                [
                    "Name": "Atorvastatin",
                    "Dosage": "20mg",
                    "Frequency": "Once daily",
                    "Duration": 30,
                    "Instructions": "Take at bedtime"
                ]
            ]
        ]
        batch.setData(prescriptionData, forDocument: prescriptionRef)
        
        // 10. Doctors Collection
        let doctorRef = db.collection("doctors").document("DOC001")
        let doctorData: [String: Any] = [
            "Doctorid": "DOC001",
            "Doctor_name": "Dr. Sarah Smith",
            "Doctor_Field": ["Filed_id": "CARD01", "Filed_name": "Cardiology"],
            "Doctor_experience": 12,
            "license_number": "MD123456",
            "Email": "sarah.smith@hospital.com",
            "phoneNo": "+1122334455",
            "Password": "hashed_doctor_password",
            "Department": "Cardiology"
        ]
        batch.setData(doctorData, forDocument: doctorRef)
        
        // 11. Doctor Notes Collection
        let doctorNoteRef = db.collection("doctorNotes").document("NOTE001")
        let doctorNoteData: [String: Any] = [
            "Note_id": "NOTE001",
            "Doctor_id": "DOC001",
            "Notes text": "Patient shows improvement in cholesterol levels",
            "createdAt": Timestamp(date: Date())
        ]
        batch.setData(doctorNoteData, forDocument: doctorNoteRef)
        
        // 12. Medical Records Collection
        let medicalRecordRef = db.collection("medicalRecords").document("REC001")
        let medicalRecordData: [String: Any] = [
            "Record_id": "REC001",
            "Patient_id": patientId,
            "Doctor_id": "DOC001",
            "Diagnosis_text": "Hyperlipidemia",
            "Prescription_text": "Atorvastatin 20mg daily",
            "createdAt": Timestamp(date: Date())
        ]
        batch.setData(medicalRecordData, forDocument: medicalRecordRef)
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                print("Error initializing database: \(error.localizedDescription)")
                completion(false, error)
            } else {
                print("All collections initialized successfully with patientId: \(patientId)")
                verifyAllData(completion: completion)
            }
        }
    }
    
    private static func verifyAllData(completion: @escaping (Bool, Error?) -> Void) {
        let collectionsToVerify = [
            "patients", "appointments", "chats", "billing", "admins",
            "nurses", "labTechs", "accountants", "prescriptions",
            "doctors", "doctorNotes", "medicalRecords"
        ]
        
        let dispatchGroup = DispatchGroup()
        var verificationError: Error?
        
        for collection in collectionsToVerify {
            dispatchGroup.enter()
            db.collection(collection).limit(to: 1).getDocuments { snapshot, error in
                if let error = error {
                    print("Verification failed for \(collection): \(error.localizedDescription)")
                    verificationError = error
                } else if snapshot?.isEmpty ?? true {
                    print("⚠️ No documents found in \(collection)")
                } else {
                    print("✅ Verified \(collection) exists with documents")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(verificationError == nil, verificationError)
        }
    }
}
