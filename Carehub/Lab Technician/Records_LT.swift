import SwiftUI
import FirebaseFirestore

// MARK: - UI Components

struct PatientRecordCard: View {
    let patient: PatientInfo
    let testCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(patient.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("ID: \(patient.patientId)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                        .font(.system(size: 12))
                    Text("Age: \(patient.age)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                }
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                        .font(.system(size: 12))
                    Text("Total Tests: \(testCount)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct Records_LT: View {
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var patients: [(PatientInfo, Int)] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let categories = ["All", "Blood Count", "Lipid Panel", "Thyroid Function", "Glucose Test", "Cholesterol Test", "Allergy Test", "Joint Fluid Analysis", "Blood Test"]

    var filteredPatients: [(PatientInfo, Int)] {
        let filtered = patients.filter { patient, _ in
            if searchText.isEmpty {
                return true
            }
            let searchLowercased = searchText.lowercased()
            return patient.name.lowercased().contains(searchLowercased) ||
                   patient.patientId.lowercased().contains(searchLowercased)
        }
        
        // Sort by testCount (descending), then by name (ascending)
        return filtered.sorted { (p1, p2) in
            if p1.1 != p2.1 {
                return p1.1 > p2.1 // Sort by testCount in descending order
            } else {
                return p1.0.name < p2.0.name // Secondary sort by name in ascending order
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.94, green: 0.94, blue: 1.0)
                    .edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    ProgressView("Loading records...")
                        .scaleEffect(1.5)
                } else if let error = errorMessage {
                    VStack {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                        Button("Retry") {
                            loadData()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else {
                    GeometryReader { geometry in
                        VStack(spacing: 0) {
                            // Fixed Header Section
                            VStack(spacing: 16) {
                                // Search Bar
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                                        .font(.system(size: 18))
                                        .padding(.leading, 12)
                                    
                                    TextField("Search by patient name or ID...", text: $searchText)
                                        .font(.system(size: 16))
                                        .padding(.vertical, 12)
                                    
                                    if !searchText.isEmpty {
                                        Button(action: {
                                            searchText = ""
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                                .padding(.trailing, 12)
                                        }
                                    }
                                }
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                
                                // Section Title with Count
                                HStack {
                                    Text(selectedCategory == "All" ? "All Records" : selectedCategory)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                                    
                                    Text("(\(filteredPatients.count))")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 14)
                            }
                            
                            // Scrollable Patient Cards
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(filteredPatients, id: \.0.patientId) { patient, testCount in
                                        NavigationLink(
                                            destination: PatientRecordView(patient: patient)
                                        ) {
                                            PatientRecordCard(patient: patient, testCount: testCount)
                                        }
                                    }
                                }
                                .padding(.bottom, 24)
                            }
                            .frame(height: geometry.size.height - 120)
                        }
                    }
                }
            }
            .navigationTitle("Patient Records")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        isLoading = true
        errorMessage = nil
        
        FirebaseManager.shared.fetchTestResults(forPatientId: "") { tests, error in
            if let error = error {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                return
            }
            
            guard let tests = tests, !tests.isEmpty else {
                self.isLoading = false
                self.errorMessage = "No medical tests found."
                return
            }
            
            var fetchedPatients: [(PatientInfo, Int)] = []
            let group = DispatchGroup()
            var uniquePatientIds: Set<String> = []
            
            for test in tests {
                guard !uniquePatientIds.contains(test.patientId) else {
                    continue
                }
                
                uniquePatientIds.insert(test.patientId)
                group.enter()
                
                FirebaseManager.shared.fetchPatientByPatientId(test.patientId) { patient, error in
                    if let error = error {
                        print("Error fetching patient for patientId \(test.patientId): \(error.localizedDescription)")
                        group.leave()
                        return
                    }
                    guard let patient = patient else {
                        print("No patient found for patientId: \(test.patientId)")
                        group.leave()
                        return
                    }
                    
                    // Fetch test count for this patient
                    FirebaseManager.shared.fetchTestResults(forPatientId: patient.patientId) { results, error in
                        if let error = error {
                            print("Error fetching test results for patientId \(patient.patientId): \(error.localizedDescription)")
                        }
                        let testCount = results?.count ?? 0
                        fetchedPatients.append((patient, testCount))
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                self.patients = fetchedPatients
                self.isLoading = false
                print("Fetched patients: \(self.patients.map { $0.0.patientId })")
            }
        }
    }
}

struct PatientRecordView: View {
    let patient: PatientInfo
    @State private var testResults: [TestResult] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedStatus = "All"
    
    let statuses = ["All", "Pending", "Completed"]

    var filteredTestResults: [TestResult] {
        let filtered = testResults.filter { result in
            selectedStatus == "All" || result.status.lowercased() == selectedStatus.lowercased()
        }
        
        return filtered.sorted { (t1, t2) in
            let status1 = t1.status.lowercased()
            let status2 = t2.status.lowercased()
            if status1 == "pending" && status2 == "completed" {
                return true
            } else if status1 == "completed" && status2 == "pending" {
                return false
            } else {
                return t1.date > t2.date
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                // Fixed Patient Info Header
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .foregroundColor(.white)
                            .padding(8)
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
                            Text(patient.name)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Text("ID: \(patient.patientId)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Text("Age: \(patient.age) years")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                }
                .padding(.top)
                
                // Scrollable Test Results
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // Status Filter Picker
                        HStack {
                            Text("Status:")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                            
                            Picker("Status", selection: $selectedStatus) {
                                ForEach(statuses, id: \.self) { status in
                                    Text(status)
                                        .foregroundColor(.black)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.vertical, 4)
                        }
                        
                        Text("Test Results")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                            .padding(.bottom, 4)
                        
                        if isLoading {
                            ProgressView("Loading test results...")
                                .padding()
                        } else if let error = errorMessage {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                        } else if filteredTestResults.isEmpty {
                            Text("No test results found.")
                                .foregroundColor(.gray)
                        } else {
                            VStack(spacing: 20) {
                                ForEach(filteredTestResults) { result in
                                    TestResultCard(result: result)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .frame(height: geometry.size.height - 120)
            }
        }
        .background(Color(red: 0.94, green: 0.94, blue: 1.0))
        .navigationTitle("Patient Records")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadTestResults()
        }
    }
    
    private func loadTestResults() {
        isLoading = true
        errorMessage = nil
        
        FirebaseManager.shared.fetchTestResults(forPatientId: patient.patientId) { results, error in
            isLoading = false
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            
            self.testResults = results ?? []
            print("Fetched test results for patient \(patient.patientId): \(self.testResults.count)")
        }
    }
}

struct InfoRow1: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
            
            Text(value.isEmpty ? "Not specified" : value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
                .padding(.bottom, 8)
            
            Divider()
        }
    }
}

struct TestResultCard: View {
    let result: TestResult
    @State private var pdfLoadError: String?
    @State private var isNavigating = false
    @State private var isLoading = false
    
    var statusColor: Color {
        switch result.status.lowercased() {
        case "completed": return .green
        case "pending": return .orange
        case "abnormal": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.testName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                Spacer()
                Text(result.date)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("Status:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                Text(result.status.capitalized)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(4)
                Spacer()
            }
            
            HStack {
                Text("Doctor:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                Text(result.doc ?? "Not specified")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black.opacity(0.7))
                Spacer()
            }
            
            if !result.pdfUrl.isEmpty {
                if let pdfUrl = URL(string: result.pdfUrl) {
                    NavigationLink(
                        destination: PDFViewer(pdfUrl: pdfUrl),
                        isActive: $isNavigating
                    ) {
                        EmptyView()
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isLoading = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isLoading = false
                                isNavigating = true
                            }
                        }
                    }) {
                        HStack {
                            Spacer()
                            ZStack {
                                Text("View PDF")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .opacity(isLoading ? 0 : 1)
                                
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                            }
                            Spacer()
                        }
                        .frame(height: 32) // Fixed height
                    }
                    .background(Color(red: 0.43, green: 0.34, blue: 0.99))
                    .cornerRadius(8)
                    .disabled(isLoading)
                }
                if let error = pdfLoadError {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct Records_LT_Previews: PreviewProvider {
    static var previews: some View {
        Records_LT()
    }
}
