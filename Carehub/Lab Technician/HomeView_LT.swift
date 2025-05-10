import SwiftUI
import FirebaseFirestore

// PatientCard View (unchanged)
struct PatientCard: View {
    let patientWithTest: PatientWithTest
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundColor(.white)
                .padding(6)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.43, green: 0.34, blue: 0.99),
                            Color(red: 0.55, green: 0.48, blue: 0.99)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.3), radius: 5, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(patientWithTest.patient.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text("Test: \(patientWithTest.medicalTest.testName)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                HStack(spacing: 4) {
                    Text("ID: \(patientWithTest.patient.patientId) | Age: \(patientWithTest.patient.age)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                        .font(.system(size: 12))
                    
                    Text(patientWithTest.medicalTest.status)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.black.opacity(0.7))
                }
            }
            .padding(.vertical, 4)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                .padding(.trailing, 8)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// HomeView_LT View (modified)
struct HomeView_LT: View {
    @State private var searchText = ""
    @State private var patientsWithTests: [PatientWithTest] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var filteredPatients: [PatientWithTest] {
        patientsWithTests.filter { patientWithTest in
            searchText.isEmpty || patientWithTest.patient.name.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.94, green: 0.94, blue: 1.0)
                    .edgesIgnoringSafeArea(.all)
                
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Fixed Header Section
                        VStack(spacing: 16) {
                            // Search Bar
                            HStack {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                                        .font(.system(size: 18))
                                        .padding(.leading, 12)
                                    
                                    TextField("Search by patient name...", text: $searchText)
                                        .font(.system(size: 16))
                                        .padding(.vertical, 12)
                                }
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                                .padding(.horizontal, 16)
                            }
                            .padding(.top, 16)
                            
                            // Pending Tests Header
                            HStack {
                                Text("Pending Tests")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                                
                                Text("(\(filteredPatients.count))")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color.gray)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 14)
                        }
                        
                        // Scrollable Patient Cards
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                if isLoading {
                                    ProgressView()
                                        .padding(.vertical, 20)
                                } else if let error = errorMessage {
                                    VStack {
                                        Text("Error: \(error)")
                                            .foregroundColor(.red)
                                        Button("Retry") {
                                            fetchPendingTests()
                                        }
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                    }
                                    .padding(.vertical, 20)
                                } else if filteredPatients.isEmpty {
                                    Text("No patients found")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                        .padding(.vertical, 20)
                                } else {
                                    ForEach(filteredPatients, id: \.id) { patientWithTest in
                                        NavigationLink(destination: UpdateTestView(medicalTestId: patientWithTest.medicalTest.id)) {
                                            PatientCard(patientWithTest: patientWithTest)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 24)
                        }
                        .frame(height: geometry.size.height - 150) // Adjust height based on header size
                    }
                }
            }
            .navigationTitle("Lab Technician")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchPendingTests()
            }
            .onDisappear {
                fetchPendingTests()
            }
        }
    }
    
    private func fetchPendingTests() {
        isLoading = true
        errorMessage = nil
        
        FirebaseManager.shared.fetchPendingTests { tests, error in
            if let error = error {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                return
            }
            
            guard let tests = tests else {
                self.isLoading = false
                self.patientsWithTests = []
                return
            }
            
            var fetchedPatientsWithTests: [PatientWithTest] = []
            let group = DispatchGroup()
            
            for test in tests {
                group.enter()
                
                FirebaseManager.shared.fetchPatientByPatientId(test.patientId) { patient, error in
                    if let error = error {
                        print("Error fetching patient for patientId \(test.patientId): \(error.localizedDescription)")
                    } else if let patient = patient {
                        let patientWithTest = PatientWithTest(id: test.id, patient: patient, medicalTest: test)
                        fetchedPatientsWithTests.append(patientWithTest)
                    } else {
                        print("No patient found for patientId: \(test.patientId)")
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.patientsWithTests = fetchedPatientsWithTests
                self.isLoading = false
                print("Fetched patients with tests: \(self.patientsWithTests.map { $0.patient.patientId })")
            }
        }
    }
}

struct HomeView_LT_Previews: PreviewProvider {
    static var previews: some View {
        HomeView_LT()
    }
}
