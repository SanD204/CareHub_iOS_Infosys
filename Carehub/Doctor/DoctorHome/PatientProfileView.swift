//import SwiftUI
//import FirebaseFirestore
//
//struct PatientProfileView: View {
//    let patientIdentifier: String
//    let doctorId: String
//    let doctorName: String
//    @State private var patientInfo: PatientProfile?
//    @State private var appointment: Appointment?
//    @State private var isFetching = true
//    @State private var errorText: String?
//    @State private var labTestsInput: String = ""
//    @State private var showNotesView = false
//    @State private var showPrescriptionView = false
//    @State private var showAlert = false
//    @State private var alertMessage = ""
//
//    private let db = Firestore.firestore()
//    
//    var body: some View {
//        ZStack {
//            Color(red: 0.96, green: 0.96, blue: 1.0)
//                .edgesIgnoringSafeArea(.all)
//            
//            if isFetching {
//                ProgressView("Fetching patient profile...")
//                    .tint(Color(red: 0.45, green: 0.36, blue: 0.98))
//            } else if let error = errorText {
//                VStack(spacing: 16) {
//                    Text("Error loading profile")
//                        .font(.system(size: 18, weight: .medium))
//                    Text(error)
//                        .font(.system(size: 14))
//                        .foregroundColor(.red)
//                        .multilineTextAlignment(.center)
//                    
//                    Button(action: {
//                        retrievePatientProfile()
//                    }) {
//                        Text("Retry")
//                            .font(.system(size: 16, weight: .semibold))
//                            .foregroundColor(.white)
//                            .padding(.vertical, 10)
//                            .padding(.horizontal, 24)
//                            .background(
//                                LinearGradient(
//                                    gradient: Gradient(colors: [
//                                        Color(red: 0.45, green: 0.36, blue: 0.98),
//                                        Color(red: 0.57, green: 0.50, blue: 0.98)
//                                    ]),
//                                    startPoint: .leading,
//                                    endPoint: .trailing
//                                )
//                            )
//                            .cornerRadius(10)
//                            .shadow(color: Color(red: 0.45, green: 0.36, blue: 0.98).opacity(0.3), radius: 5, x: 0, y: 3)
//                    }
//                }
//                .padding()
//            } else if let patient = patientInfo {
//                ScrollView {
//                    VStack(spacing: 16) {
//                        profileCard(patient: patient)
//                        vitalStatsSection(patient: patient)
//                        actionButtons()
//                        labRequestSection()
//                        Spacer(minLength: 20)
//                    }
//                    .padding(.top, 16)
//                    .padding(.horizontal, 16)
//                }
//            }
//        }
//        .navigationTitle("Patient Profile")
//        .navigationBarTitleDisplayMode(.inline)
//        .navigationDestination(isPresented: $showNotesView) {
//            if let appointment = appointment, !doctorId.isEmpty {
//                NotesView(appointment: appointment)
//            } else {
//                Text("No appointment found for this patient.")
//                    .foregroundColor(.red)
//            }
//        }
//        .navigationDestination(isPresented: $showPrescriptionView) {
//            if let appointment = appointment, !doctorId.isEmpty {
//                PrescriptionView(appointment: appointment)
//            } else {
//                Text("No appointment found for this patient.")
//                    .foregroundColor(.red)
//            }
//        }
//        .alert(isPresented: $showAlert) {
//            Alert(
//                title: Text("Lab Test Request"),
//                message: Text(alertMessage),
//                dismissButton: .default(Text("OK")) {
//                    if alertMessage.contains("Successfully") {
//                        labTestsInput = ""
//                    }
//                }
//            )
//        }
//        .onAppear {
//            retrievePatientProfile()
//        }
//    }
//    
//    private func profileCard(patient: PatientProfile) -> some View {
//        VStack(alignment: .leading, spacing: 12) {
//            ProfileDetailRow(title: "Patient ID", value: patient.patientIdentifier, icon: "person.text.rectangle")
//            Divider()
//                .background(Color.gray.opacity(0.2))
//            
//            ProfileDetailRow(title: "Name", value: patient.profileData.fullName, icon: "person.fill")
//            ProfileDetailRow(title: "Contact", value: patient.profileData.contactNumber, icon: "phone.fill")
//            ProfileDetailRow(title: "Email", value: patient.profileData.emailAddress, icon: "envelope.fill")
//            
//            if !patient.healthData.allergyList.isEmpty {
//                MultiProfileRow(
//                    title: "Allergies",
//                    value: patient.healthData.allergyList.joined(separator: ", "),
//                    icon: "allergens"
//                )
//            }
//        }
//        .padding(.vertical, 14)
//        .padding(.horizontal, 16)
//        .background(
//            RoundedRectangle(cornerRadius: 14)
//                .fill(Color.white)
//                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
//        )
//        .padding(.vertical, 8)
//    }
//    
//    private func vitalStatsSection(patient: PatientProfile) -> some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("Vitals")
//                .font(.system(size: 18, weight: .bold))
//                .foregroundColor(Color(red: 0.45, green: 0.36, blue: 0.98))
//                .padding(.horizontal, 16)
//            
//            HStack(spacing: 16) {
//                VitalStatCard(
//                    title: "BP",
//                    value: patient.healthData.bloodPressure.last?.reading ?? "N/A",
//                    icon: "heart.fill",
//                    color: Color(red: 0.45, green: 0.36, blue: 0.98)
//                )
//                
//                VitalStatCard(
//                    title: "Heart Rate",
//                    value: patient.healthData.heartRate.last?.reading ?? "N/A",
//                    icon: "waveform.path.ecg",
//                    color: Color(red: 0.57, green: 0.50, blue: 0.98)
//                )
//            }
//            
//            HStack(spacing: 16) {
//                VitalStatCard(
//                    title: "Temperature",
//                    value: patient.healthData.temperature.last?.reading ?? "N/A",
//                    icon: "thermometer",
//                    color: Color(red: 0.45, green: 0.36, blue: 0.98)
//                )
//                
//                VitalStatCard(
//                    title: "Weight",
//                    value: patient.healthData.weight.last?.reading ?? "N/A",
//                    icon: "scalemass",
//                    color: Color(red: 0.57, green: 0.50, blue: 0.98)
//                )
//            }
//        }
//        .padding(.vertical, 14)
//        .padding(.horizontal, 16)
//        .background(
//            RoundedRectangle(cornerRadius: 14)
//                .fill(Color.white)
//                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
//        )
//        .padding(.vertical, 8)
//    }
//    
//    private func actionButtons() -> some View {
//        HStack(spacing: 16) {
//            Button(action: {
//                print("Add Notes button tapped, showNotesView: \(showNotesView)")
//                if appointment == nil || doctorId.isEmpty {
//                    print("Cannot navigate to NotesView: appointment is nil or doctorId is empty")
//                    errorText = "No appointment found or invalid doctor ID."
//                    return
//                }
//                showNotesView = true
//            }) {
//                Text("Add Notes")
//                    .font(.system(size: 16, weight: .semibold))
//                    .foregroundColor(.white)
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 12)
//                    .background(Color(red: 0.45, green: 0.36, blue: 0.98))
//                    .cornerRadius(10)
//            }
//            
//            Button(action: {
//                print("Add Prescription button tapped, showPrescriptionView: \(showPrescriptionView)")
//                if appointment == nil || doctorId.isEmpty {
//                    print("Cannot navigate to PrescriptionView: appointment is nil or doctorId is empty")
//                    errorText = "No appointment found or invalid doctor ID."
//                    return
//                }
//                showPrescriptionView = true
//            }) {
//                Text("Add Prescription")
//                    .font(.system(size: 16, weight: .semibold))
//                    .foregroundColor(.white)
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 12)
//                    .background(Color(red: 0.57, green: 0.50, blue: 0.98))
//                    .cornerRadius(10)
//            }
//        }
//        .padding(.horizontal, 16)
//        .padding(.vertical, 8)
//    }
//    
//    private func labRequestSection() -> some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("Request Lab Tests")
//                .font(.system(size: 18, weight: .bold))
//                .foregroundColor(Color(red: 0.45, green: 0.36, blue: 0.98))
//                .padding(.horizontal, 16)
//            
//            TextEditor(text: $labTestsInput)
//                .font(.system(size: 16))
//                .frame(minHeight: 100)
//                .padding(8)
//                .background(Color(.systemGray6))
//                .cornerRadius(8)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 8)
//                        .stroke(Color(red: 0.45, green: 0.36, blue: 0.98), lineWidth: 1)
//                )
//                .padding(.horizontal, 16)
//            
//            Button(action: {
//                requestLabTest()
//            }) {
//                Text("Request Lab")
//                    .font(.system(size: 16, weight: .semibold))
//                    .foregroundColor(.white)
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 12)
//                    .background(Color(red: 0.45, green: 0.36, blue: 0.98))
//                    .cornerRadius(10)
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//        }
//        .background(
//            RoundedRectangle(cornerRadius: 14)
//                .fill(Color.white)
//                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
//        )
//        .padding(.vertical, 8)
//    }
//    
//    private func retrievePatientProfile() {
//        isFetching = true
//        errorText = nil
//        
//        let db = Firestore.firestore()
//        db.collection("patients").document(patientIdentifier).getDocument { document, error in
//            if let error = error {
//                print("Error fetching patient by document ID: \(error.localizedDescription)")
//                db.collection("patients").whereField("patientId", isEqualTo: patientIdentifier).getDocuments { querySnapshot, queryError in
//                    if let queryError = queryError {
//                        self.errorText = "Failed to fetch data: \(queryError.localizedDescription)"
//                        self.isFetching = false
//                        return
//                    }
//                    
//                    guard let documents = querySnapshot?.documents, !documents.isEmpty else {
//                        self.errorText = "Patient not found"
//                        self.isFetching = false
//                        print("No patient found for patientId: \(patientIdentifier)")
//                        return
//                    }
//                    
//                    let document = documents.first!
//                    do {
//                        let patientData = try self.parsePatientProfile(document: document)
//                        self.patientInfo = patientData
//                        self.fetchAppointment()
//                    } catch {
//                        self.errorText = "Error parsing data: \(error.localizedDescription)"
//                        self.isFetching = false
//                    }
//                }
//                return
//            }
//            
//            guard let document = document, document.exists else {
//                db.collection("patients").whereField("patientId", isEqualTo: patientIdentifier).getDocuments { querySnapshot, queryError in
//                    if let queryError = queryError {
//                        self.errorText = "Failed to fetch data: \(queryError.localizedDescription)"
//                        self.isFetching = false
//                        return
//                    }
//                    
//                    guard let documents = querySnapshot?.documents, !documents.isEmpty else {
//                        self.errorText = "Patient not found"
//                        self.isFetching = false
//                        print("No patient found for patientId: \(patientIdentifier)")
//                        return
//                    }
//                    
//                    let document = documents.first!
//                    do {
//                        let patientData = try self.parsePatientProfile(document: document)
//                        self.patientInfo = patientData
//                        self.fetchAppointment()
//                    } catch {
//                        self.errorText = "Error parsing data: \(error.localizedDescription)"
//                        self.isFetching = false
//                    }
//                }
//                return
//            }
//            
//            do {
//                let patientData = try self.parsePatientProfile(document: document)
//                self.patientInfo = patientData
//                self.fetchAppointment()
//            } catch {
//                self.errorText = "Error parsing data: \(error.localizedDescription)"
//                self.isFetching = false
//            }
//        }
//    }
//    
//    private func fetchAppointment() {
//        db.collection("appointments")
//            .whereField("patientId", isEqualTo: patientIdentifier)
//            .whereField("docId", isEqualTo: doctorId)
//            .getDocuments { querySnapshot, error in
//                if let error = error {
//                    print("Error fetching appointment: \(error.localizedDescription)")
//                    self.errorText = "Failed to fetch appointment: \(error.localizedDescription)"
//                    self.isFetching = false
//                    return
//                }
//                
//                guard let documents = querySnapshot?.documents, !documents.isEmpty else {
//                    print("No appointment found for patientId: \(patientIdentifier) and docId: \(doctorId)")
//                    self.errorText = "No appointment found for this patient and doctor."
//                    self.isFetching = false
//                    return
//                }
//                
//                let document = documents.first!
//                do {
//                    let appointmentData = try self.parseAppointment(document: document)
//                    self.appointment = appointmentData
//                    self.isFetching = false
//                } catch {
//                    self.errorText = "Error parsing appointment data: \(error.localizedDescription)"
//                    self.isFetching = false
//                }
//            }
//    }
//    
//    private func parsePatientProfile(document: DocumentSnapshot) throws -> PatientProfile {
//        guard let data = document.data() else {
//            throw NSError(domain: "DataParsingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Document data was empty"])
//        }
//        
//        guard let profileDataMap = data["userData"] as? [String: Any] else {
//            throw NSError(domain: "DataParsingError", code: 2, userInfo: [NSLocalizedDescriptionKey: "UserData not found"])
//        }
//        
//        let profileData = ProfileData(
//            fullName: profileDataMap["Name"] as? String ?? "Unknown",
//            dateOfBirth: profileDataMap["Dob"] as? String ?? "",
//            emailAddress: profileDataMap["Email"] as? String ?? "No email",
//            contactNumber: profileDataMap["phoneNo"] as? String ?? "No phone"
//        )
//        
//        var healthData = HealthData(allergyList: [], bloodPressure: [], heartRate: [], temperature: [], weight: [])
//        if let healthDataMap = data["vitals"] as? [String: Any] {
//            if let allergiesArray = healthDataMap["allergies"] as? [String] {
//                healthData.allergyList = allergiesArray
//            }
//            if let bpArray = healthDataMap["bp"] as? [[String: Any]] {
//                healthData.bloodPressure = bpArray.compactMap { bpData in
//                    guard let reading = bpData["value"] as? String,
//                          let timestamp = bpData["timestamp"] as? Timestamp else { return nil }
//                    return HealthEntry(timestamp: timestamp.dateValue(), reading: reading)
//                }
//            }
//            if let hrArray = healthDataMap["heartRate"] as? [[String: Any]] {
//                healthData.heartRate = hrArray.compactMap { hrData in
//                    guard let reading = hrData["value"] as? String,
//                          let timestamp = hrData["timestamp"] as? Timestamp else { return nil }
//                    return HealthEntry(timestamp: timestamp.dateValue(), reading: reading)
//                }
//            }
//            if let tempArray = healthDataMap["temperature"] as? [[String: Any]] {
//                healthData.temperature = tempArray.compactMap { tempData in
//                    guard let reading = tempData["value"] as? String,
//                          let timestamp = tempData["timestamp"] as? Timestamp else { return nil }
//                    return HealthEntry(timestamp: timestamp.dateValue(), reading: reading)
//                }
//            }
//            if let weightArray = healthDataMap["weight"] as? [[String: Any]] {
//                healthData.weight = weightArray.compactMap { weightData in
//                    guard let reading = weightData["value"] as? String,
//                          let timestamp = weightData["timestamp"] as? Timestamp else { return nil }
//                    return HealthEntry(timestamp: timestamp.dateValue(), reading: reading)
//                }
//            }
//        }
//        
//        let patientIdentifier = data["patientId"] as? String ?? document.documentID
//        
//        return PatientProfile(
//            patientIdentifier: patientIdentifier,
//            profileData: profileData,
//            healthData: healthData
//        )
//    }
//    
//    private func parseAppointment(document: DocumentSnapshot) throws -> Appointment {
//        guard let data = document.data() else {
//            throw NSError(domain: "DataParsingError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Appointment document data was empty"])
//        }
//        
//        let id = document.documentID
//        let apptId = data["apptId"] as? String ?? ""
//        let patientId = data["patientId"] as? String ?? ""
//        let description = data["description"] as? String ?? ""
//        let docId = data["docId"] as? String ?? ""
//        let status = data["status"] as? String ?? ""
//        let billingStatus = data["billingStatus"] as? String ?? ""
//        let amount = data["amount"] as? Double
//        let date = (data["date"] as? Timestamp)?.dateValue()
//        let doctorsNotes = data["doctorsNotes"] as? String
//        let prescriptionId = data["prescriptionId"] as? String
//        let followUpRequired = data["followUpRequired"] as? Bool
//        let followUpDate = (data["followUpDate"] as? Timestamp)?.dateValue()
//        
//        return Appointment(
//            id: id,
//            apptId: apptId,
//            patientId: patientId,
//            description: description,
//            docId: docId,
//            status: status,
//            billingStatus: billingStatus,
//            amount: amount,
//            date: date,
//            doctorsNotes: doctorsNotes,
//            prescriptionId: prescriptionId,
//            followUpRequired: followUpRequired,
//            followUpDate: followUpDate
//        )
//    }
//    
//    private func requestLabTest() {
//        guard !labTestsInput.isEmpty else {
//            alertMessage = "Please enter the tests required."
//            showAlert = true
//            return
//        }
//        
//        let currentDate = Date()
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd"
//        let dateString = formatter.string(from: currentDate)
//        
//        let labTestId = UUID().uuidString
//        
//        let testData: [String: Any] = [
//            "date": dateString,
//            "doc": doctorName,
//            "id": labTestId,
//            "patientId": patientIdentifier,
//            "pdfUrl": "",
//            "status": "Pending",
//            "testName": labTestsInput
//        ]
//        
//        db.collection("medicalTests").addDocument(data: testData) { error in
//            if let error = error {
//                alertMessage = "Error requesting lab test: \(error.localizedDescription)"
//                showAlert = true
//                print("Error adding lab test request: \(error.localizedDescription)")
//            } else {
//                alertMessage = "Successfully Requested"
//                showAlert = true
//                print("Lab test requested successfully: \(labTestsInput)")
//            }
//        }
//    }
//}
//
//struct ProfileDetailRow: View {
//    let title: String
//    let value: String
//    let icon: String
//    
//    var body: some View {
//        HStack(spacing: 12) {
//            Image(systemName: icon)
//                .foregroundColor(Color(red: 0.45, green: 0.36, blue: 0.98))
//                .font(.system(size: 14))
//                .frame(width: 24)
//            
//            Text(title)
//                .font(.system(size: 16, weight: .medium))
//                .foregroundColor(.black)
//            
//            Spacer()
//            
//            Text(value)
//                .font(.system(size: 16, weight: .regular))
//                .foregroundColor(.gray)
//        }
//        .padding(.vertical, 8)
//    }
//}
//
//struct MultiProfileRow: View {
//    let title: String
//    let value: String
//    let icon: String
//    
//    var body: some View {
//        HStack(alignment: .top, spacing: 12) {
//            Image(systemName: icon)
//                .foregroundColor(Color(red: 0.45, green: 0.36, blue: 0.98))
//                .font(.system(size: 14))
//                .frame(width: 24)
//            
//            Text(title)
//                .font(.system(size: 16, weight: .medium))
//                .foregroundColor(.black)
//            
//            Spacer()
//            
//            Text(value)
//                .font(.system(size: 16, weight: .regular))
//                .foregroundColor(.gray)
//                .frame(maxWidth: .infinity, alignment: .trailing)
//        }
//        .padding(.vertical, 8)
//    }
//}
//
//struct VitalStatCard: View {
//    let title: String
//    let value: String
//    let icon: String
//    let color: Color
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            HStack(spacing: 6) {
//                Image(systemName: icon)
//                    .foregroundColor(color)
//                    .font(.system(size: 14))
//                
//                Text(title)
//                    .font(.system(size: 14, weight: .medium))
//                    .foregroundColor(.gray)
//            }
//            
//            Text(value)
//                .font(.system(size: 20, weight: .semibold))
//                .foregroundColor(color)
//                .padding(.top, 2)
//        }
//        .padding(12)
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .frame(height: 80)
//        .background(
//            RoundedRectangle(cornerRadius: 12)
//                .fill(Color.white)
//                .shadow(color: color.opacity(0.1), radius: 4, x: 0, y: 2)
//        )
//    }
//}
//
//struct ProfileData {
//    let fullName: String
//    let dateOfBirth: String
//    let emailAddress: String
//    let contactNumber: String
//}
//
//struct HealthData {
//    var allergyList: [String]
//    var bloodPressure: [HealthEntry]
//    var heartRate: [HealthEntry]
//    var temperature: [HealthEntry]
//    var weight: [HealthEntry]
//}
//
//struct HealthEntry {
//    let timestamp: Date
//    let reading: String
//}
//
//struct PatientProfile {
//    let patientIdentifier: String
//    let profileData: ProfileData
//    let healthData: HealthData
//}

import SwiftUI
import Firebase
import FirebaseFirestore
import UniformTypeIdentifiers
import FirebaseStorage

// MARK: - PrescriptionImagePicker
struct PrescriptionImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PrescriptionImagePicker

        init(_ parent: PrescriptionImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.onImagePicked(uiImage)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - PrescriptionDocumentPicker
struct PrescriptionDocumentPicker: UIViewControllerRepresentable {
    let onDocumentPicked: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: PrescriptionDocumentPicker

        init(_ parent: PrescriptionDocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.onDocumentPicked(url)
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            controller.dismiss(animated: true)
        }
    }
}

struct PatientProfileView: View {
    let patientIdentifier: String
    let doctorId: String
    let doctorName: String
    @State private var patientInfo: PatientProfile?
    @State private var appointment: Appointment?
    @State private var isFetching = true
    @State private var errorText: String?
    @State private var labTestsInput: String = "Blood Test" // Default selection
    @State private var showNotesView = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var followUpRequired: Bool = false
    @State private var showActionSheet = false
    @State private var showImagePicker = false
    @State private var showDocumentPicker = false
    @State private var selectedImage: UIImage?
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isUploading = false
    @State private var uploadStatus: String = ""
    @State private var pdfFileName: String = "" // New state to store PDF file name
    let apptId: String
    @State private var alertTitle: String = ""
    @State private var selectedTestCategory: String = "Blood Test"
    @State private var selectedSpecificTest: String = "Complete Blood Count"

    private let db = Firestore.firestore()
    private let labTestOptions: [String: [String]] = [
        "Blood Test": ["Complete Blood Count", "Lipid Panel", "Blood Glucose", "Thyroid Function"],
        "Urine Test": ["Urinalysis", "Urine Culture", "Microalbumin"],
        "X-Ray": ["Chest X-Ray", "Spinal X-Ray", "Joint X-Ray"],
        "MRI": ["Brain MRI", "Spinal MRI", "Joint MRI"],
        "Ultrasound": ["Abdominal Ultrasound", "Pelvic Ultrasound", "Thyroid Ultrasound"],
        "ECG": ["Resting ECG", "Stress ECG"]
    ]
    private let purpleColor = Color(hex: "6D57FC")

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)

                if isFetching {
                    ProgressView("Fetching patient profile...")
                        .tint(purpleColor)
                } else if let error = errorText {
                    VStack(spacing: 16) {
                        Text("Error loading profile")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)

                        Button(action: {
                            retrievePatientProfile()
                        }) {
                            Text("Retry")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 24)
                                .background(purpleColor)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else if let patient = patientInfo {
                    ScrollView {
                        VStack(spacing: 16) {
                            profileCard(patient: patient)
                            vitalStatsSection(patient: patient)
                            actionButtons()
                            prescriptionSection()
                            labRequestSection()
                            followUpSection()
                            markAsCompletedButton()
                            Spacer(minLength: 20)
                        }
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("Patient Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showNotesView) {
                if let appointment = appointment, !doctorId.isEmpty {
                    NotesView(appointment: appointment)
                } else {
                    Text("No appointment found for this patient.")
                        .foregroundColor(.red)
                }
            }
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(
                    title: Text("Select Prescription Source"),
                    buttons: [
                        .default(Text("Camera")) {
                            sourceType = .camera
                            showImagePicker = true
                        },
                        .default(Text("Photo Library")) {
                            sourceType = .photoLibrary
                            showImagePicker = true
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showImagePicker) {
                PrescriptionImagePicker(image: $selectedImage, sourceType: sourceType, onImagePicked: uploadPrescription)
            }
            .sheet(isPresented: $showDocumentPicker) {
                PrescriptionDocumentPicker { url in
                    uploadDocument(url: url)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertMessage.contains("Successfully") {
                            labTestsInput = "None"
                        }
                    }
                )
            }
            .onAppear {
                initializeFirebase()
                retrievePatientProfile()
            }
        }
    }

    private func profileCard(patient: PatientProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ProfileDetailRow(title: "Patient ID", value: patient.patientIdentifier, icon: "person.text.rectangle")
            Divider()

            ProfileDetailRow(title: "Name", value: patient.profileData.fullName, icon: "person.fill")
            ProfileDetailRow(title: "Contact", value: patient.profileData.contactNumber, icon: "phone.fill")
            ProfileDetailRow(title: "Email", value: patient.profileData.emailAddress, icon: "envelope.fill")

            if !patient.healthData.allergyList.isEmpty {
                MultiProfileRow(
                    title: "Allergies",
                    value: patient.healthData.allergyList.joined(separator: ", "),
                    icon: "allergens"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(radius: 2)
        .padding(.horizontal)
    }

    private func vitalStatsSection(patient: PatientProfile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vitals")
                .font(.headline)
                .foregroundColor(purpleColor)
                .padding(.horizontal)

            HStack(spacing: 16) {
                VitalStatCard(
                    title: "BP",
                    value: patient.healthData.bloodPressure.last?.reading ?? "N/A",
                    icon: "heart.fill",
                    color: purpleColor
                )

                VitalStatCard(
                    title: "Heart Rate",
                    value: patient.healthData.heartRate.last?.reading ?? "N/A",
                    icon: "waveform.path.ecg",
                    color: purpleColor
                )
            }

            HStack(spacing: 16) {
                VitalStatCard(
                    title: "Temperature",
                    value: patient.healthData.temperature.last?.reading ?? "N/A",
                    icon: "thermometer",
                    color: purpleColor
                )

                VitalStatCard(
                    title: "Weight",
                    value: patient.healthData.weight.last?.reading ?? "N/A",
                    icon: "scalemass",
                    color: purpleColor
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(radius: 2)
        .padding(.horizontal)
    }

    private func actionButtons() -> some View {
        HStack(spacing: 16) {
            Button(action: {
                if appointment == nil || doctorId.isEmpty {
                    errorText = "No appointment found or invalid doctor ID."
                    return
                }
                showNotesView = true
            }) {
                Text("Add Notes")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(purpleColor)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }

    @State private var showPDFViewer = false // Add this state to control PDF viewer navigation

    private func prescriptionSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prescription")
                .font(.headline)
                .foregroundColor(purpleColor)
                .padding(.horizontal)

            if isUploading {
                ProgressView("Uploading...")
                    .padding(.horizontal)
            } else if uploadStatus.contains("success") {
                Text(uploadStatus)
                    .foregroundColor(.green)
                    .padding(.horizontal)
            } else if uploadStatus.contains("failed") && !pdfFileName.isEmpty {
                // Show the PDF name as a button when upload fails
                Button(action: {
                    // Retry uploading the same document
                    if let lastURL = appointment?.prescriptionId, let url = URL(string: lastURL) {
                        uploadDocument(url: url)
                    }
                }) {
                    Text(pdfFileName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(purpleColor)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .padding(.horizontal)
                    .onTapGesture {
                        // Show full-screen image on tap if needed
                    }
            } else if let currentURLString = appointment?.prescriptionId, !currentURLString.isEmpty {
                // Check if the URL points to a PDF
                if currentURLString.lowercased().hasSuffix(".pdf") {
                    Button(action: {
                        showPDFViewer = true
                    }) {
                        Text("View Prescription PDF")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(purpleColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(Color(.systemGray5))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                } else {
                    // Handle image URL
                    if let url = URL(string: currentURLString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .padding(.horizontal)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .padding(.horizontal)
                                    .onTapGesture {
                                        // Show full-screen image on tap if needed
                                    }
                            case .failure(let error):
                                VStack {
                                    Text("Failed to load prescription image")
                                        .foregroundColor(.red)
                                    Text("Error: \(error.localizedDescription)")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    Button(action: {
                                        // Retry loading the image
                                    }) {
                                        Text("Retry")
                                            .foregroundColor(purpleColor)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal)
                                            .background(Color(.systemGray5))
                                            .cornerRadius(10)
                                    }
                                }
                                .padding(.horizontal)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Text("Invalid image URL")
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
            }

            if !uploadStatus.contains("failed") || pdfFileName.isEmpty {
                // Show the "Add Prescription" or "Prescription Added" button
                Button(action: {
                    showActionSheet = true
                }) {
                    Text(appointment?.prescriptionId == nil ? "Add Prescription" : "Add Prescription")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(purpleColor)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(radius: 2)
        .padding(.horizontal)
        .navigationDestination(isPresented: $showPDFViewer) {
            if let urlString = appointment?.prescriptionId, let url = URL(string: urlString) {
                PDFViewer(pdfUrl: url)
            } else {
                Text("Failed to load PDF URL")
                    .foregroundColor(.red)
            }
        }
    }

    private func labRequestSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Request Lab Tests")
                .font(.headline)
                .foregroundColor(purpleColor)
                .padding(.horizontal)

            HStack(spacing: 8) {
                Picker("Test Category", selection: $selectedTestCategory) {
                    ForEach(labTestOptions.keys.sorted(), id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
                .onChange(of: selectedTestCategory) { newCategory in
                    if let firstTest = labTestOptions[newCategory]?.first {
                        selectedSpecificTest = firstTest
                    }
                }

                Picker("Specific Test", selection: $selectedSpecificTest) {
                    if let specificTests = labTestOptions[selectedTestCategory] {
                        ForEach(specificTests, id: \.self) { test in
                            Text(test).tag(test)
                        }
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal)

            Button(action: {
                requestLabTest()
            }) {
                Text("Request Lab")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(purpleColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(radius: 2)
        .padding(.horizontal)
    }

    private func followUpSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Follow-Up")
                .font(.headline)
                .foregroundColor(purpleColor)
                .padding(.horizontal)

            Toggle(isOn: $followUpRequired) {
                Text("Follow-Up Required")
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(.horizontal)
            .onChange(of: followUpRequired) { newValue in
                updateFollowUpRequiredInDB(newValue: newValue)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(radius: 2)
        .padding(.horizontal)
    }

    private func markAsCompletedButton() -> some View {
        Button(action: {
            updateAppointmentStatus()
        }) {
            Text(appointment?.status == "Completed" ? "Completed" : "Mark as Completed")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(appointment?.status == "Completed" ? Color.gray : purpleColor) // Gray out if completed
                .cornerRadius(10)
        }
        .disabled(appointment?.status == "Completed") // Disable the button if already completed
        .padding(.horizontal)
        .padding(.vertical)
    }
    private func initializeFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    private func retrievePatientProfile() {
        isFetching = true
        errorText = nil

        let db = Firestore.firestore()
        db.collection("patients").document(patientIdentifier).getDocument { document, error in
            if let error = error {
                print("Error fetching patient by document ID: \(error.localizedDescription)")
                db.collection("patients").whereField("patientId", isEqualTo: patientIdentifier).getDocuments { querySnapshot, queryError in
                    if let queryError = queryError {
                        self.errorText = "Failed to fetch data: \(queryError.localizedDescription)"
                        self.isFetching = false
                        return
                    }

                    guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                        self.errorText = "Patient not found"
                        self.isFetching = false
                        print("No patient found for patientId: \(patientIdentifier)")
                        return
                    }

                    let document = documents.first!
                    do {
                        let patientData = try self.parsePatientProfile(document: document)
                        self.patientInfo = patientData
                        self.fetchAppointment()
                    } catch {
                        self.errorText = "Error parsing data: \(error.localizedDescription)"
                        self.isFetching = false
                    }
                }
                return
            }

            guard let document = document, document.exists else {
                db.collection("patients").whereField("patientId", isEqualTo: patientIdentifier).getDocuments { querySnapshot, queryError in
                    if let queryError = queryError {
                        self.errorText = "Failed to fetch data: \(queryError.localizedDescription)"
                        self.isFetching = false
                        return
                    }

                    guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                        self.errorText = "Patient not found"
                        self.isFetching = false
                        print("No patient found for patientId: \(patientIdentifier)")
                        return
                    }

                    let document = documents.first!
                    do {
                        let patientData = try self.parsePatientProfile(document: document)
                        self.patientInfo = patientData
                        self.fetchAppointment()
                    } catch {
                        self.errorText = "Error parsing data: \(error.localizedDescription)"
                        self.isFetching = false
                    }
                }
                return
            }

            do {
                let patientData = try self.parsePatientProfile(document: document)
                self.patientInfo = patientData
                self.fetchAppointment()
            } catch {
                self.errorText = "Error parsing data: \(error.localizedDescription)"
                self.isFetching = false
            }
        }
    }

    private func fetchAppointment() {
        db.collection("appointments")
            .whereField("apptId", isEqualTo: apptId)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching appointment: \(error.localizedDescription)")
                    self.errorText = "Failed to fetch appointment: \(error.localizedDescription)"
                    self.isFetching = false
                    return
                }

                guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                    print("No appointment found for apptId: \(self.apptId)")
                    self.errorText = "No appointment found for this appointment ID."
                    self.isFetching = false
                    return
                }

                let document = documents.first!
                do {
                    let appointmentData = try self.parseAppointment(document: document)
                    self.appointment = appointmentData
                    self.followUpRequired = appointmentData.followUpRequired ?? false
                    // Print the appointment ID to the console
                    if !appointmentData.apptId.isEmpty {
                        print("Current appointment ID: \(appointmentData.apptId)")
                    } else {
                        print("Current appointment ID (Firestore document ID): \(appointmentData.id)")
                    }
                    self.isFetching = false
                } catch {
                    self.errorText = "Error parsing appointment data: \(error.localizedDescription)"
                    self.isFetching = false
                }
            }
    }
    private func parsePatientProfile(document: DocumentSnapshot) throws -> PatientProfile {
        guard let data = document.data() else {
            throw NSError(domain: "DataParsingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Document data was empty"])
        }

        guard let profileDataMap = data["userData"] as? [String: Any] else {
            throw NSError(domain: "DataParsingError", code: 2, userInfo: [NSLocalizedDescriptionKey: "UserData not found"])
        }

        let profileData = ProfileData(
            fullName: profileDataMap["Name"] as? String ?? "Unknown",
            dateOfBirth: profileDataMap["Dob"] as? String ?? "",
            emailAddress: profileDataMap["Email"] as? String ?? "No email",
            contactNumber: profileDataMap["phoneNo"] as? String ?? "No phone"
        )

        var healthData = HealthData(allergyList: [], bloodPressure: [], heartRate: [], temperature: [], weight: [])
        if let healthDataMap = data["vitals"] as? [String: Any] {
            if let allergiesArray = healthDataMap["allergies"] as? [String] {
                healthData.allergyList = allergiesArray
            }
            if let bpArray = healthDataMap["bp"] as? [[String: Any]] {
                healthData.bloodPressure = bpArray.compactMap { bpData in
                    guard let reading = bpData["value"] as? String,
                          let timestamp = bpData["timestamp"] as? Timestamp else { return nil }
                    return HealthEntry(timestamp: timestamp.dateValue(), reading: reading)
                }
            }
            if let hrArray = healthDataMap["heartRate"] as? [[String: Any]] {
                healthData.heartRate = hrArray.compactMap { hrData in
                    guard let reading = hrData["value"] as? String,
                          let timestamp = hrData["timestamp"] as? Timestamp else { return nil }
                    return HealthEntry(timestamp: timestamp.dateValue(), reading: reading)
                }
            }
            if let tempArray = healthDataMap["temperature"] as? [[String: Any]] {
                healthData.temperature = tempArray.compactMap { tempData in
                    guard let reading = tempData["value"] as? String,
                          let timestamp = tempData["timestamp"] as? Timestamp else { return nil }
                    return HealthEntry(timestamp: timestamp.dateValue(), reading: reading)
                }
            }
            if let weightArray = healthDataMap["weight"] as? [[String: Any]] {
                healthData.weight = weightArray.compactMap { weightData in
                    guard let reading = weightData["value"] as? String,
                          let timestamp = weightData["timestamp"] as? Timestamp else { return nil }
                    return HealthEntry(timestamp: timestamp.dateValue(), reading: reading)
                }
            }
        }

        let patientIdentifier = data["patientId"] as? String ?? document.documentID

        return PatientProfile(
            patientIdentifier: patientIdentifier,
            profileData: profileData,
            healthData: healthData
        )
    }

    private func parseAppointment(document: DocumentSnapshot) throws -> Appointment {
        guard let data = document.data() else {
            throw NSError(domain: "DataParsingError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Appointment document data was empty"])
        }

        let id = document.documentID
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

    private func requestLabTest() {
        guard !labTestsInput.isEmpty else {
            alertTitle = "Lab Test Request"
            alertMessage = "Please select a test."
            showAlert = true
            return
        }

        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: currentDate)

        let labTestId = UUID().uuidString

        // Combine test category and specific test with hyphen
        let combinedTestName = "\(selectedTestCategory) - \(selectedSpecificTest)"

        let testData: [String: Any] = [
            "date": dateString,
            "doc": doctorName,
            "id": labTestId,
            "patientId": patientIdentifier,
            "pdfUrl": "",
            "status": "Pending",
            "testName": combinedTestName  // Only sending the combined name
            // Removed the separate testCategory field
        ]

        db.collection("medicalTests").addDocument(data: testData) { error in
            if let error = error {
                self.alertTitle = "Lab Test Request"
                self.alertMessage = "Error requesting lab test: \(error.localizedDescription)"
                self.showAlert = true
                print("Error adding lab test request: \(error.localizedDescription)")
            } else {
                self.alertTitle = "Lab Test Request"
                self.alertMessage = "Successfully Requested"
                self.showAlert = true
                print("Lab test requested successfully: \(combinedTestName)")
            }
        }
    }
    private func updateFollowUpRequiredInDB(newValue: Bool) {
        guard let appointment = appointment else {
            print("No appointment found to update followUpRequired")
            return
        }

        db.collection("appointments").document(appointment.id).updateData([
            "followUpRequired": newValue,
            "doc": doctorName,
            "updatedAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error updating followUpRequired: \(error.localizedDescription)")
                self.alertTitle = "Follow-Up Status"
                self.alertMessage = "Error updating follow-up status: \(error.localizedDescription)"
                self.showAlert = true
            } else {
                print("Successfully updated followUpRequired to \(newValue)")
            }
        }
    }

    private func uploadPrescription(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            uploadStatus = "Error processing image"
            print("Error processing image")
            isUploading = false
            return
        }

        guard let appointment = appointment else {
            uploadStatus = "No appointment found"
            print("No appointment found")
            isUploading = false
            return
        }

        isUploading = true
        uploadStatus = ""

        let storage = Storage.storage()
        let storageRef = storage.reference()
        let prescriptionRef = storageRef.child("prescriptions/\(appointment.id)/\(UUID().uuidString).jpg")

        // Upload the image data to Firebase Storage
        let uploadTask = prescriptionRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                self.uploadStatus = "Upload failed: \(error.localizedDescription)"
                self.isUploading = false
                print("Upload failed: \(error.localizedDescription)")
                return
            }

            // Get the download URL
            prescriptionRef.downloadURL { url, error in
                self.isUploading = false
                if let error = error {
                    self.uploadStatus = "Failed to get download URL: \(error.localizedDescription)"
                    print("Failed to get download URL: \(error.localizedDescription)")
                } else if let downloadURL = url {
                    self.updatePrescriptionURL(newURL: downloadURL.absoluteString)
                } else {
                    self.uploadStatus = "No download URL received"
                    print("No download URL received")
                }
            }
        }

        // Observe upload progress or errors
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error {
                self.uploadStatus = "Upload failed: \(error.localizedDescription)"
                self.isUploading = false
                print("Upload failed with error: \(error.localizedDescription)")
            }
        }
    }

    private func uploadDocument(url: URL) {
        guard let appointment = appointment else {
            uploadStatus = "No appointment found"
            print("No appointment found")
            isUploading = false
            return
        }

        // Store the PDF file name
        pdfFileName = url.lastPathComponent

        isUploading = true
        uploadStatus = ""

        let storage = Storage.storage()
        let storageRef = storage.reference()
        let prescriptionRef = storageRef.child("prescriptions/\(appointment.id)/\(UUID().uuidString)_\(url.lastPathComponent)")

        // Start accessing the security-sensitive file
        let success = url.startAccessingSecurityScopedResource()
        defer {
            if success {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // Upload the file to Firebase Storage with retry logic
        let uploadTask = prescriptionRef.putFile(from: url, metadata: nil) { metadata, error in
            if let error = error {
                self.uploadStatus = "Upload failed: \(error.localizedDescription)"
                self.isUploading = false
                print("Upload failed: \(error.localizedDescription)")
                return
            }

            // Get the download URL
            prescriptionRef.downloadURL { url, error in
                self.isUploading = false
                if let error = error {
                    self.uploadStatus = "Failed to get download URL: \(error.localizedDescription)"
                    print("Failed to get download URL: \(error.localizedDescription)")
                } else if let downloadURL = url {
                    self.updatePrescriptionURL(newURL: downloadURL.absoluteString)
                } else {
                    self.uploadStatus = "No download URL received"
                    print("No download URL received")
                }
            }
        }

        // Observe upload progress or errors
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error {
                self.uploadStatus = "Upload failed: \(error.localizedDescription)"
                self.isUploading = false
                print("Upload failed with error: \(error.localizedDescription)")
            }
        }
    }

    private func updatePrescriptionURL(newURL: String) {
        guard let appointment = appointment else {
            uploadStatus = "No appointment found"
            isUploading = false
            print("No appointment found")
            return
        }

        let prescriptionRef = db.collection("appointments").document(appointment.id)

        prescriptionRef.updateData([
            "prescriptionId": newURL,
            "doc": doctorName,
            "updatedAt": FieldValue.serverTimestamp()
        ]) { error in
            isUploading = false
            if let error = error {
                uploadStatus = "Failed to update Firestore: \(error.localizedDescription)"
                print("Failed to update Firestore: \(error.localizedDescription)")
            } else {
                uploadStatus = "Prescription uploaded successfully"
                print("Prescription uploaded successfully: \(newURL)")
                self.appointment?.prescriptionId = newURL
                // Reset pdfFileName after successful upload
                self.pdfFileName = ""
            }
        }
    }
    private func updateAppointmentStatus() {
        guard let appointment = appointment else {
            return
        }

        db.collection("appointments").document(appointment.id).updateData([
            "status": "Completed",
            "doc": doctorName,
            "updatedAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                self.alertTitle = "Appointment Status"
                self.alertMessage = "Error marking as completed: \(error.localizedDescription)"
                self.showAlert = true
            } else {
                self.appointment?.status = "Completed"
                print("Updated appointment status to: \(self.appointment?.status ?? "Unknown")")
                self.alertTitle = "Appointment Status"
                self.alertMessage = "Appointment marked as completed"
                self.showAlert = true
            }
        }
    }
}

struct ProfileDetailRow: View {
    let title: String
    let value: String
    let icon: String
    private let purpleColor = Color(hex: "6D57FC")

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(purpleColor)
                .font(.system(size: 14))
                .frame(width: 24)

            Text(title)
                .font(.system(size: 16, weight: .medium))

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

struct MultiProfileRow: View {
    let title: String
    let value: String
    let icon: String
    private let purpleColor = Color(hex: "6D57FC")

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(purpleColor)
                .font(.system(size: 14))
                .frame(width: 24)

            Text(title)
                .font(.system(size: 16, weight: .medium))

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 8)
    }
}

struct VitalStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }

            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
                .padding(.top, 2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 80)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct ProfileData {
    let fullName: String
    let dateOfBirth: String
    let emailAddress: String
    let contactNumber: String
}

struct HealthData {
    var allergyList: [String]
    var bloodPressure: [HealthEntry]
    var heartRate: [HealthEntry]
    var temperature: [HealthEntry]
    var weight: [HealthEntry]
}

struct HealthEntry {
    let timestamp: Date
    let reading: String
}

struct PatientProfile {
    let patientIdentifier: String
    let profileData: ProfileData
    let healthData: HealthData
}
