import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct Patient: Identifiable {
    let id = UUID()
    let name: String
    let visitDate: String
    let patientId: String
}

struct MyPatientsView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var searchText = ""
    @State private var patients: [Patient] = []
    @State private var doctorId: String = ""
    
    private let db = Firestore.firestore()
    @State private var listener: ListenerRegistration?
    private let backgroundColor = Color(red: 0.97, green: 0.97, blue: 1.0)
    private let accentColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    
    var filteredPatients: [Patient] {
        if searchText.isEmpty {
            return patients
        } else {
            return patients.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    // Header with title and search bar
                    VStack(spacing: 16) {
                        PatientSearchBar(text: $searchText, placeholder: "Search patients")
                            .padding(.horizontal)
                    }
                    
                    if filteredPatients.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 60))
                                .foregroundColor(accentColor.opacity(0.3))
                            
                            Text("No patients found")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            if !searchText.isEmpty {
                                Text("Try a different search term")
                                    .font(.subheadline)
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredPatients) { patient in
                                    NavigationLink {
                                        DetailsPresriptionView(patientId: patient.patientId)
                                    } label: {
                                        PatientInfoCard(patient: patient)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
            .navigationTitle("My Patients")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Patients")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                }
            }
            .onAppear {
                fetchDoctorIdAndPatients()
            }
            .onDisappear {
                listener?.remove()
                listener = nil
            }
        }
    }
    
    private func fetchDoctorIdAndPatients() {
        guard let uid = Auth.auth().currentUser?.uid else {
            doctorId = ""
            patients = []
            return
        }
        
        db.collection("doctors").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching doctor: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data(), snapshot?.exists == true,
                  let docId = data["Doctorid"] as? String else {
                print("No doctor data found for uid: \(uid)")
                doctorId = ""
                patients = []
                return
            }
            
            doctorId = docId
            fetchPatients()
        }
    }
    
    private func fetchPatients() {
        guard !doctorId.isEmpty else {
            patients = []
            return
        }
        
        listener?.remove()
        
        listener = db.collection("appointments")
            .whereField("docId", isEqualTo: doctorId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching appointments: \(error)")
                    patients = []
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No appointment documents found for docId: \(doctorId)")
                    patients = []
                    return
                }
                
                let patientIds = Set(documents.compactMap { $0.data()["patientId"] as? String })
                
                var fetchedPatients: [Patient] = []
                let group = DispatchGroup()
                
                for patientId in patientIds {
                    group.enter()
                    db.collection("patients")
                        .whereField("patientId", isEqualTo: patientId)
                        .getDocuments { patientSnapshot, patientError in
                            defer { group.leave() }
                            
                            if let error = patientError {
                                print("Error fetching patient \(patientId): \(error)")
                                return
                            }
                            
                            guard let patientDoc = patientSnapshot?.documents.first else {
                                print("No patient document found for patientId: \(patientId)")
                                return
                            }
                            
                            let data = patientDoc.data()
                            
                            guard let userData = data["userData"] as? [String: Any] else {
                                print("Invalid or missing userData for patientId: \(patientId)")
                                return
                            }
                            
                            let name = userData["Name"] as? String ?? "Unknown"
                            
                            let patientAppointments = documents.filter { $0.data()["patientId"] as? String == patientId }
                            let mostRecentDate = patientAppointments
                                .compactMap { ($0.data()["date"] as? Timestamp)?.dateValue() }
                                .max()
                            
                            let visitDateString = mostRecentDate?.formatted(.dateTime.day().month(.abbreviated).year().hour().minute()) ?? "N/A"
                            
                            let patient = Patient(
                                name: name,
                                visitDate: "Last visit: \(visitDateString)",
                                patientId: patientId
                            )
                            fetchedPatients.append(patient)
                        }
                }
                
                group.notify(queue: .main) {
                    patients = fetchedPatients.sorted { $0.name < $1.name }
                    print("Total patients fetched: \(patients.count)")
                }
            }
    }
}

struct PatientSearchBar: View {
    @Binding var text: String
    let placeholder: String
    private let accentColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(accentColor.opacity(0.7))
                .font(.system(size: 16))
            
            TextField(placeholder, text: $text)
                .foregroundColor(.primary)
                .font(.system(size: 16))
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
    }
}

struct PatientInfoCard: View {
    let patient: Patient
    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
            
            HStack(spacing: 16) {
                // Avatar with gradient border
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    primaryColor.opacity(0.7),
                                    primaryColor.opacity(0.5)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Text(String(patient.name.prefix(1)))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(patient.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(patient.visitDate)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Chevron inside the card
                Image(systemName: "chevron.right")
                    .foregroundColor(primaryColor.opacity(0.6))
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MyPatientsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MyPatientsView()
        }
    }
}
