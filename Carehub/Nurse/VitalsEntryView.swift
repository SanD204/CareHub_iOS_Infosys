//import SwiftUI
//import Firebase
//
//struct NurseVitalsEntryView: View {
//    let patientId: String  // Changed from nurseId to patientId since we're focusing on vitals entry
//    @State private var bpSystolic = 120
//    @State private var bpDiastolic = 80
//    @State private var weight = 70.0
//    @State private var height = 170.0
//    @State private var allergies = ""
//    @State private var heartRate = 72
//    @State private var temperature = 98.6
//    @State private var showAlert = false
//    @State private var alertMessage = ""
//    @State private var isLoading = false
//    @State private var patientName = ""
//    @State private var activeSheet: ActiveSheet?
//    
//    enum ActiveSheet: Identifiable {
//        case systolic, diastolic, weight, height, heartRate, temperature
//        
//        var id: Int {
//            hashValue
//        }
//    }
//
//    let primaryColor = Color(red: 109/255, green: 87/255, blue: 252/255)
//    @Environment(\.colorScheme) var colorScheme
//    @Environment(\.dismiss) var dismiss
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                // Background
//                if colorScheme == .dark {
//                    Color(.systemBackground)
//                        .edgesIgnoringSafeArea(.all)
//                } else {
//                    LinearGradient(
//                        colors: [
//                            Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.1),
//                            Color(.systemBackground).opacity(0.9),
//                            Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.1)
//                        ],
//                        startPoint: .topLeading,
//                        endPoint: .bottomTrailing
//                    )
//                    .edgesIgnoringSafeArea(.all)
//                }
//                
//                // Content
//                if isLoading {
//                    ProgressView()
//                        .scaleEffect(1.5)
//                        .progressViewStyle(CircularProgressViewStyle(tint: primaryColor))
//                } else {
//                    ScrollView {
//                        VStack(spacing: 32) {
//                            patientInfoCard
//                            vitalsForm
//                        }
//                        .padding(.vertical)
//                    }
//                }
//            }
//            .navigationTitle("Enter Vitals")
//            .navigationBarTitleDisplayMode(.large)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Close") {
//                        dismiss()
//                    }
//                    .foregroundColor(primaryColor)
//                }
//            }
//            .onAppear {
//                fetchPatientDetails()
//            }
//            .alert("Alert", isPresented: $showAlert) {
//                Button("OK", role: .cancel) { }
//            } message: {
//                Text(alertMessage)
//            }
//            .sheet(item: $activeSheet) { item in
//                pickerSheet(for: item)
//            }
//        }
//    }
//    
//    // MARK: - View Components
//    
//    private var patientInfoCard: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            HStack(spacing: 12) {
//                Image(systemName: "person.crop.circle.fill")
//                    .font(.title2)
//                    .foregroundColor(primaryColor)
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text("Patient Record")
//                        .font(.headline)
//                        .foregroundColor(.secondary)
//                    
//                    Text(patientId)
//                        .font(.title3.bold())
//                }
//            }
//            .padding(.bottom, 4)
//            
//            Divider()
//            
//            if !patientName.isEmpty {
//                VStack(alignment: .leading, spacing: 10) {
//                    DetailRow(icon: "person.text.rectangle", label: "Name", value: patientName)
//                }
//                .padding(.top, 4)
//            }
//        }
//        .padding()
//        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : .white)
//        .cornerRadius(14)
//        .shadow(color: colorScheme == .dark ? .clear : .primary.opacity(0.1), radius: 5, x: 0, y: 2)
//        .padding(.horizontal)
//        .padding(.top, 16)
//    }
//
//    private struct DetailRow: View {
//        let icon: String
//        let label: String
//        let value: String
//        @Environment(\.colorScheme) var colorScheme
//        
//        var body: some View {
//            HStack(alignment: .top, spacing: 12) {
//                Image(systemName: icon)
//                    .foregroundColor(Color(red: 109/255, green: 87/255, blue: 252/255))
//                    .frame(width: 24)
//                
//                VStack(alignment: .leading, spacing: 2) {
//                    Text(label)
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                    
//                    Text(value)
//                        .font(.body)
//                }
//            }
//        }
//    }
//    
//    private var vitalsForm: some View {
//        VStack(spacing: 32) {
//            Group {
//                bloodPressureSection
//                vitalValueRow(title: "Weight", value: weight, unit: "kg", systemImage: "scalemass", sheet: .weight)
//                vitalValueRow(title: "Height", value: height, unit: "cm", systemImage: "ruler", sheet: .height)
//                vitalValueRow(title: "Heart Rate", value: Double(heartRate), unit: "bpm", systemImage: "heart.fill", sheet: .heartRate)
//                vitalValueRow(title: "Temperature", value: temperature, unit: "°F", systemImage: "thermometer", sheet: .temperature)
//                allergySection
//            }
//            .padding(.horizontal, 32)
//            .padding(.vertical, 4)
//            saveButton
//                .padding(.top, 8)
//        }
//    }
//    
//    private var bloodPressureSection: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                Image(systemName: "waveform.path.ecg")
//                    .foregroundColor(primaryColor)
//                Text("Blood Pressure")
//                    .foregroundColor(.secondary)
//                    .font(.title3)
//                    .fontWeight(.semibold)
//            }
//            .font(.title3)
//            .fontWeight(.semibold)
//            
//            HStack(spacing: 16) {
//                Button(action: { activeSheet = .systolic }) {
//                    vitalValueButton(title: "Systolic", value: "\(bpSystolic)", unit: "mmHg")
//                }
//                
//                Text("/")
//                    .font(.title2)
//                    .fontWeight(.bold)
//                    .foregroundColor(.primary)
//                
//                Button(action: { activeSheet = .diastolic }) {
//                    vitalValueButton(title: "Diastolic", value: "\(bpDiastolic)", unit: "mmHg")
//                }
//            }
//        }
//    }
//    
//    private func vitalValueButton(title: String, value: String, unit: String) -> some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text(title)
//                .font(.custom("SFProDisplay-Medium", size: 18))
//                .foregroundColor(colorScheme == .dark ? .white : .black)
//            
//            HStack {
//                Text(value)
//                    .font(.custom("SFProDisplay-Medium", size: 16))
//                    .foregroundStyle(colorScheme == .dark ? .white : .black)
//                    .fontWeight(.semibold)
//                Text(unit)
//                    .font(.body)
//                    .foregroundColor(.secondary)
//                Spacer()
//                Image(systemName: "chevron.right")
//                    .foregroundColor(Color(.tertiaryLabel))
//            }
//            .padding(12)
//            .background(colorScheme == .dark ? Color(.tertiarySystemBackground) : .white)
//            .overlay(
//                RoundedRectangle(cornerRadius: 10)
//                    .stroke(Color(.tertiaryLabel).opacity(0.2), lineWidth: 1)
//                    .cornerRadius(10)
//            )
//        }
//        .frame(maxWidth: .infinity)
//    }
//    
//    private func vitalValueRow(title: String, value: Double, unit: String, systemImage: String, sheet: ActiveSheet) -> some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                Image(systemName: systemImage)
//                    .foregroundColor(primaryColor)
//                Text(title)
//                    .foregroundColor(.secondary)
//            }
//            .font(.title3)
//            .fontWeight(.semibold)
//            
//            Button(action: { activeSheet = sheet }) {
//                HStack {
//                    Text(String(format: value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", value))
//                        .font(.custom("SFProDisplay-Medium", size: 18))
//                        .foregroundStyle(colorScheme == .dark ? .white : .black)
//                        .fontWeight(.semibold)
//                    Text(unit)
//                        .font(.body)
//                        .foregroundColor(.secondary)
//                    Spacer()
//                    Image(systemName: "chevron.right")
//                        .foregroundColor(Color(.tertiaryLabel))
//                }
//                .padding(12)
//                .background(colorScheme == .dark ? Color(.tertiarySystemBackground) : .white)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 10)
//                        .stroke(Color(.tertiaryLabel).opacity(0.2), lineWidth: 1)
//                )
//                .cornerRadius(10)
//            }
//        }
//    }
//    
//    private var allergySection: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                Image(systemName: "allergens")
//                    .foregroundColor(primaryColor)
//                Text("Allergies")
//                    .foregroundColor(.secondary)
//                    .font(.title3)
//                    .fontWeight(.semibold)
//            }
//            .font(.title3)
//            .fontWeight(.semibold)
//            
//            TextField("Peanuts, Dust, etc.", text: $allergies)
//                .textFieldStyle(.plain)
//                .padding(12)
//                .background(colorScheme == .dark ? Color(.tertiarySystemBackground) : .white)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 10)
//                        .stroke(Color(.tertiaryLabel).opacity(0.2), lineWidth: 1)
//                    .cornerRadius(10)
//                )
//        }
//    }
//    
//    private var saveButton: some View {
//        Button(action: saveVitals) {
//            Label("Save Vitals", systemImage: "")
//                .font(.headline)
//                .frame(maxWidth: .infinity)
//                .frame(height: 50)
//        }
//        .buttonStyle(.borderedProminent)
//        .tint(primaryColor)
//        .padding(.horizontal)
//        .padding(.bottom, 8)
//    }
//    
//    private func pickerSheet(for item: ActiveSheet) -> some View {
//        VStack(spacing: 0) {
//            Capsule()
//                .frame(width: 36, height: 5)
//                .foregroundColor(Color(.systemGray5))
//                .padding(.top, 8)
//                .padding(.bottom, 16)
//            
//            Group {
//                switch item {
//                case .systolic:
//                    IntPicker(value: $bpSystolic, range: 80...200, title: "Systolic", unit: "mmHg")
//                case .diastolic:
//                    IntPicker(value: $bpDiastolic, range: 40...130, title: "Diastolic", unit: "mmHg")
//                case .weight:
//                    DecimalPicker(value: $weight, range: 30...200, title: "Weight", unit: "kg")
//                case .height:
//                    DecimalPicker(value: $height, range: 100...220, title: "Height", unit: "cm")
//                case .heartRate:
//                    IntPicker(value: $heartRate, range: 40...200, title: "Heart Rate", unit: "bpm")
//                case .temperature:
//                    DecimalPicker(value: $temperature, range: 94...108, title: "Temperature", unit: "°F")
//                }
//            }
//            .padding(.horizontal)
//            
//            Button(action: { activeSheet = nil }) {
//                Text("Done")
//                    .font(.headline)
//                    .frame(maxWidth: .infinity)
//                    .frame(height: 50)
//            }
//            .buttonStyle(.borderedProminent)
//            .tint(primaryColor)
//            .padding()
//        }
//        .presentationDetents([.height(300)])
//        .presentationDragIndicator(.visible)
//        .interactiveDismissDisabled()
//        .background(Color(.systemBackground))
//    }
//    
//    // MARK: - Helper Views
//    
//    struct IntPicker: View {
//        @Binding var value: Int
//        let range: ClosedRange<Int>
//        let title: String
//        let unit: String
//        
//        var body: some View {
//            VStack {
//                Text("\(title): \(value) \(unit)")
//                    .font(.headline)
//                    .padding(.bottom, 8)
//                
//                Picker("", selection: $value) {
//                    ForEach(range, id: \.self) { num in
//                        Text("\(num)").tag(num)
//                    }
//                }
//                .pickerStyle(.wheel)
//            }
//        }
//    }
//    
//    struct DecimalPicker: View {
//        @Binding var value: Double
//        let range: ClosedRange<Double>
//        let title: String
//        let unit: String
//        let step: Double
//        
//        init(value: Binding<Double>, range: ClosedRange<Double>, title: String, unit: String, step: Double = 0.1) {
//            self._value = value
//            self.range = range
//            self.title = title
//            self.unit = unit
//            self.step = step
//        }
//        
//        var body: some View {
//            VStack {
//                Text("\(title): \(String(format: value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", value)) \(unit)")
//                    .font(.headline)
//                    .padding(.bottom, 8)
//                
//                Picker("", selection: $value) {
//                    ForEach(Array(stride(from: range.lowerBound, through: range.upperBound, by: step)), id: \.self) { num in
//                        Text(String(format: num.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", num)).tag(num)
//                    }
//                }
//                .pickerStyle(.wheel)
//            }
//        }
//    }
//    
//    // MARK: - Functions
//    
//    private func fetchPatientDetails() {
//        startLoading()
//        FirebaseService.shared.fetchPatientName(patientID: patientId) { result in
//            DispatchQueue.main.async {
//                self.stopLoading()
//                switch result {
//                case .success(let name):
//                    self.patientName = name
//                    self.fetchPatientVitals()
//                case .failure(let error):
//                    print("Error fetching name: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//    
//    private func fetchPatientVitals() {
//        FirebaseService.shared.fetchPatientVitals(patientID: patientId) { result in
//            stopLoading()
//            
//            switch result {
//            case .success(let vitals):
//                populateVitals(vitals)
//            case .failure(let error):
//                showAlert(message: "Error loading vitals: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    private func saveVitals() {
//        uploadVitals()
//    }
//    
//    private func uploadVitals() {
//        startLoading()
//        
//        let vitalsData: [String: Any] = [
//            "bp": "\(bpSystolic)/\(bpDiastolic)",
//            "weight": String(format: "%.1f", weight),
//            "height": String(format: "%.1f", height),
//            "allergies": allergies,
//            "heartRate": String(heartRate),
//            "temperature": String(format: "%.1f", temperature),
//            "timestamp": FieldValue.serverTimestamp()
//        ]
//        
//        FirebaseService.shared.savePatientVitals(patientID: patientId, vitals: vitalsData) { result in
//            stopLoading()
//            
//            switch result {
//            case .success:
//                showAlert(message: "Vitals saved successfully!")
//            case .failure(let error):
//                showAlert(message: "Error: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    private func populateVitals(_ vitals: [String: Any]) {
//        if let bp = vitals["bp"] as? String {
//            let components = bp.components(separatedBy: "/")
//            if components.count == 2 {
//                bpSystolic = Int(components[0]) ?? 120
//                bpDiastolic = Int(components[1]) ?? 80
//            }
//        }
//        
//        if let weightStr = vitals["weight"] as? String, let weightValue = Double(weightStr) {
//            weight = weightValue
//        }
//        
//        if let heightStr = vitals["height"] as? String, let heightValue = Double(heightStr) {
//            height = heightValue
//        }
//        
//        allergies = vitals["allergies"] as? String ?? ""
//        
//        if let heartRateStr = vitals["heartRate"] as? String, let heartRateValue = Int(heartRateStr) {
//            heartRate = heartRateValue
//        }
//        
//        if let tempStr = vitals["temperature"] as? String, let tempValue = Double(tempStr) {
//            temperature = tempValue
//        }
//    }
//    
//    private func startLoading() {
//        withAnimation { isLoading = true }
//    }
//    
//    private func stopLoading() {
//        withAnimation { isLoading = false }
//    }
//    
//    private func showAlert(message: String) {
//        alertMessage = message
//        showAlert = true
//    }
//}
//
//#Preview {
//    Group {
//        NurseVitalsEntryView(patientId: "PAT001")
//            .preferredColorScheme(.light)
//    }
//}

import SwiftUI
import Firebase

struct NurseVitalsEntryView: View {
    let patientId: String
    @State private var bpSystolic = ""
    @State private var bpDiastolic = ""
    @State private var weight = ""
    @State private var height = ""
    @State private var allergies = ""
    @State private var heartRate = ""
    @State private var temperature = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var patientName = ""
    @State private var activeSheet: ActiveSheet?
    @State private var validationErrors: [String: String] = [:]
    
    enum ActiveSheet: Identifiable {
        case systolic, diastolic, heartRate, temperature
        
        var id: Int {
            hashValue
        }
    }

    let primaryColor = Color(red: 109/255, green: 87/255, blue: 252/255)
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    // Validation ranges
    private let systolicRange = 80...200
    private let diastolicRange = 40...130
    private let weightRange = 30.0...200.0 // kg (now Double)
    private let heightRange = 100.0...220.0 // cm (now Double)
    private let heartRateRange = 40...200 // bpm
    private let temperatureRange = 94.0...108.0 // °F (now Double)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                if colorScheme == .dark {
                    Color(.systemBackground)
                        .edgesIgnoringSafeArea(.all)
                } else {
                    LinearGradient(
                        colors: [
                            Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.1),
                            Color(.systemBackground).opacity(0.9),
                            Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .edgesIgnoringSafeArea(.all)
                }
                
                // Content
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: primaryColor))
                } else {
                    ScrollView {
                        VStack(spacing: 32) {
                            patientInfoCard
                            vitalsForm
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Enter Vitals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(primaryColor)
                }
            }
            .onAppear {
                fetchPatientDetails()
            }
            .alert("Alert", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(item: $activeSheet) { item in
                pickerSheet(for: item)
            }
        }
    }
    
    // MARK: - View Components
    
    private var patientInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundColor(primaryColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Patient Record")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(patientId)
                        .font(.title3.bold())
                }
            }
            .padding(.bottom, 4)
            
            Divider()
            
            if !patientName.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    DetailRow(icon: "person.text.rectangle", label: "Name", value: patientName)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : .white)
        .cornerRadius(14)
        .shadow(color: colorScheme == .dark ? .clear : .primary.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.top, 16)
    }

    private struct DetailRow: View {
        let icon: String
        let label: String
        let value: String
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(Color(red: 109/255, green: 87/255, blue: 252/255))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.body)
                }
            }
        }
    }
    
    private var vitalsForm: some View {
        VStack(spacing: 32) {
            Group {
                bloodPressureSection
                weightSection
                heightSection
                vitalValueRow(title: "Heart Rate", value: $heartRate, unit: "bpm", systemImage: "heart.fill", sheet: .heartRate)
                vitalValueRow(title: "Temperature", value: $temperature, unit: "°F", systemImage: "thermometer", sheet: .temperature)
                allergySection
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 4)
            saveButton
                .padding(.top, 8)
        }
    }
    
    private var bloodPressureSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(primaryColor)
                Text("Blood Pressure")
                    .foregroundColor(.secondary)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .font(.title3)
            .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                Button(action: { activeSheet = .systolic }) {
                    vitalValueButton(title: "Systolic", value: bpSystolic, unit: "mmHg", error: validationErrors["systolic"])
                }
                
                Text("/")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Button(action: { activeSheet = .diastolic }) {
                    vitalValueButton(title: "Diastolic", value: bpDiastolic, unit: "mmHg", error: validationErrors["diastolic"])
                }
            }
        }
    }
    
    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "scalemass")
                    .foregroundColor(primaryColor)
                Text("Weight")
                    .foregroundColor(.secondary)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            NumericTextField(value: $weight, placeholder: "Enter weight", unit: "kg")
                .keyboardType(.decimalPad)
            
            if let error = validationErrors["weight"] {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
        }
    }
    
    private var heightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "ruler")
                    .foregroundColor(primaryColor)
                Text("Height")
                    .foregroundColor(.secondary)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            NumericTextField(value: $height, placeholder: "Enter height", unit: "cm")
                .keyboardType(.decimalPad)
            
            if let error = validationErrors["height"] {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
        }
    }
    
    private func vitalValueButton(title: String, value: String, unit: String, error: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.custom("SFProDisplay-Medium", size: 18))
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            HStack {
                Text(value.isEmpty ? "--" : value)
                    .font(.custom("SFProDisplay-Medium", size: 16))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .fontWeight(.semibold)
                Text(unit)
                    .font(.body)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(12)
            .background(colorScheme == .dark ? Color(.tertiarySystemBackground) : .white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(error != nil ? Color.red : Color(.tertiaryLabel).opacity(0.2), lineWidth: 1)
                    .cornerRadius(10)
            )
            
            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func vitalValueRow(title: String, value: Binding<String>, unit: String, systemImage: String, sheet: ActiveSheet) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(primaryColor)
                Text(title)
                    .foregroundColor(.secondary)
            }
            .font(.title3)
            .fontWeight(.semibold)
            
            Button(action: { activeSheet = sheet }) {
                HStack {
                    Text(value.wrappedValue.isEmpty ? "--" : value.wrappedValue)
                        .font(.custom("SFProDisplay-Medium", size: 18))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .fontWeight(.semibold)
                    Text(unit)
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(12)
                .background(colorScheme == .dark ? Color(.tertiarySystemBackground) : .white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(validationErrors[sheet.key] != nil ? Color.red : Color(.tertiaryLabel).opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(10)
            }
            
            if let error = validationErrors[sheet.key] {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
        }
    }
    
    private var allergySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "allergens")
                    .foregroundColor(primaryColor)
                Text("Allergies")
                    .foregroundColor(.secondary)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .font(.title3)
            .fontWeight(.semibold)
            
            TextField("Peanuts, Dust, etc.", text: $allergies)
                .textFieldStyle(.plain)
                .padding(12)
                .background(colorScheme == .dark ? Color(.tertiarySystemBackground) : .white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.tertiaryLabel).opacity(0.2), lineWidth: 1)
                    .cornerRadius(10)
                )
        }
    }
    
    private var saveButton: some View {
        Button(action: saveVitals) {
            Label("Save Vitals", systemImage: "")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(primaryColor)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private func pickerSheet(for item: ActiveSheet) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .frame(width: 36, height: 5)
                .foregroundColor(Color(.systemGray5))
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            Group {
                switch item {
                case .systolic:
                    IntPicker(value: $bpSystolic, range: systolicRange, title: "Systolic", unit: "mmHg")
                case .diastolic:
                    IntPicker(value: $bpDiastolic, range: diastolicRange, title: "Diastolic", unit: "mmHg")
                case .heartRate:
                    IntPicker(value: $heartRate, range: heartRateRange, title: "Heart Rate", unit: "bpm")
                case .temperature:
                    DecimalPicker(value: $temperature, range: temperatureRange, title: "Temperature", unit: "°F")
                }
            }
            .padding(.horizontal)
            
            Button(action: { activeSheet = nil }) {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(primaryColor)
            .padding()
        }
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Helper Views
    
    struct IntPicker: View {
        @Binding var value: String
        let range: ClosedRange<Int>
        let title: String
        let unit: String
        
        var body: some View {
            VStack {
                Text("\(title): \(value) \(unit)")
                    .font(.headline)
                    .padding(.bottom, 8)
                
                Picker("", selection: Binding(
                    get: { Int(value) ?? range.lowerBound },
                    set: { value = "\($0)" }
                )) {
                    ForEach(range, id: \.self) { num in
                        Text("\(num)").tag(num)
                    }
                }
                .pickerStyle(.wheel)
            }
        }
    }
    
    struct DecimalPicker: View {
        @Binding var value: String
        let range: ClosedRange<Double>
        let title: String
        let unit: String
        let step: Double
        
        init(value: Binding<String>, range: ClosedRange<Double>, title: String, unit: String, step: Double = 0.1) {
            self._value = value
            self.range = range
            self.title = title
            self.unit = unit
            self.step = step
        }
        
        var body: some View {
            VStack {
                Text("\(title): \(value) \(unit)")
                    .font(.headline)
                    .padding(.bottom, 8)
                
                Picker("", selection: Binding(
                    get: { Double(value) ?? range.lowerBound },
                    set: { value = String(format: $0.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", $0) }
                )) {
                    ForEach(Array(stride(from: range.lowerBound, through: range.upperBound, by: step)), id: \.self) { num in
                        Text(String(format: num.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", num)).tag(num)
                    }
                }
                .pickerStyle(.wheel)
            }
        }
    }
    
    struct NumericTextField: View {
        @Binding var value: String
        let placeholder: String
        let unit: String
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            HStack {
                TextField(placeholder, text: $value)
                    .keyboardType(.decimalPad)
                    .onChange(of: value) { newValue in
                        // Filter out non-numeric characters
                        let filtered = newValue.filter { "0123456789.".contains($0) }
                        // Ensure only one decimal point
                        let decimalCount = filtered.filter { $0 == "." }.count
                        if decimalCount <= 1 {
                            value = filtered
                        } else {
                            value = String(filtered.dropLast())
                        }
                    }
                
                if !value.isEmpty {
                    Text(unit)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(colorScheme == .dark ? Color(.tertiarySystemBackground) : .white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.tertiaryLabel).opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(10)
        }
    }
    
    // MARK: - Functions
    
    private func fetchPatientDetails() {
        startLoading()
        FirebaseService.shared.fetchPatientName(patientID: patientId) { result in
            DispatchQueue.main.async {
                self.stopLoading()
                switch result {
                case .success(let name):
                    self.patientName = name
                    self.fetchPatientVitals()
                case .failure(let error):
                    print("Error fetching name: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func fetchPatientVitals() {
        FirebaseService.shared.fetchPatientVitals(patientID: patientId) { result in
            stopLoading()
            
            switch result {
            case .success(let vitals):
                populateVitals(vitals)
            case .failure(let error):
                showAlert(message: "Error loading vitals: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveVitals() {
        guard validateFields() else {
            return
        }
        
        uploadVitals()
    }
    
    private func validateFields() -> Bool {
        var isValid = true
        var errors = [String: String]()
        
        // Validate systolic BP
        if let systolic = Int(bpSystolic) {
            if !systolicRange.contains(systolic) {
                errors["systolic"] = "Must be between \(systolicRange.lowerBound)-\(systolicRange.upperBound)"
                isValid = false
            }
        } else if !bpSystolic.isEmpty {
            errors["systolic"] = "Invalid value"
            isValid = false
        }
        
        // Validate diastolic BP
        if let diastolic = Int(bpDiastolic) {
            if !diastolicRange.contains(diastolic) {
                errors["diastolic"] = "Must be between \(diastolicRange.lowerBound)-\(diastolicRange.upperBound)"
                isValid = false
            }
        } else if !bpDiastolic.isEmpty {
            errors["diastolic"] = "Invalid value"
            isValid = false
        }
        
        // Validate weight
        if let weightValue = Double(weight) {
            if !weightRange.contains(weightValue) {
                errors["weight"] = "Must be between \(Int(weightRange.lowerBound))-\(Int(weightRange.upperBound)) kg"
                isValid = false
            }
        } else if !weight.isEmpty {
            errors["weight"] = "Invalid value"
            isValid = false
        }
        
        // Validate height
        if let heightValue = Double(height) {
            if !heightRange.contains(heightValue) {
                errors["height"] = "Must be between \(Int(heightRange.lowerBound))-\(Int(heightRange.upperBound)) cm"
                isValid = false
            }
        } else if !height.isEmpty {
            errors["height"] = "Invalid value"
            isValid = false
        }
        
        // Validate heart rate
        if let hr = Int(heartRate) {
            if !heartRateRange.contains(hr) {
                errors["heartRate"] = "Must be between \(heartRateRange.lowerBound)-\(heartRateRange.upperBound) bpm"
                isValid = false
            }
        } else if !heartRate.isEmpty {
            errors["heartRate"] = "Invalid value"
            isValid = false
        }
        
        // Validate temperature
        if let temp = Double(temperature) {
            if !temperatureRange.contains(temp) {
                errors["temperature"] = "Must be between \(temperatureRange.lowerBound)-\(temperatureRange.upperBound) °F"
                isValid = false
            }
        } else if !temperature.isEmpty {
            errors["temperature"] = "Invalid value"
            isValid = false
        }
        
        validationErrors = errors
        return isValid
    }
    
    private func uploadVitals() {
        startLoading()
        
        let vitalsData: [String: Any] = [
            "bp": "\(bpSystolic)/\(bpDiastolic)",
            "weight": weight.isEmpty ? "" : String(format: "%.1f", Double(weight) ?? ""),
            "height": height.isEmpty ? "" : String(format: "%.1f", Double(height) ?? ""),
            "allergies": allergies,
            "heartRate": heartRate,
            "temperature": temperature.isEmpty ? "" : String(format: "%.1f", Double(temperature) ?? ""),
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        FirebaseService.shared.savePatientVitals(patientID: patientId, vitals: vitalsData) { result in
            stopLoading()
            
            switch result {
            case .success:
                showAlert(message: "Vitals saved successfully!")
            case .failure(let error):
                showAlert(message: "Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func populateVitals(_ vitals: [String: Any]) {
        if let bp = vitals["bp"] as? String {
            let components = bp.components(separatedBy: "/")
            if components.count == 2 {
                bpSystolic = components[0]
                bpDiastolic = components[1]
            }
        }
        
        if let weightStr = vitals["weight"] as? String {
            weight = weightStr
        }
        
        if let heightStr = vitals["height"] as? String {
            height = heightStr
        }
        
        allergies = vitals["allergies"] as? String ?? ""
        
        if let heartRateStr = vitals["heartRate"] as? String {
            heartRate = heartRateStr
        }
        
        if let tempStr = vitals["temperature"] as? String {
            temperature = tempStr
        }
    }
    
    private func startLoading() {
        withAnimation { isLoading = true }
    }
    
    private func stopLoading() {
        withAnimation { isLoading = false }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

extension NurseVitalsEntryView.ActiveSheet {
    var key: String {
        switch self {
        case .systolic: return "systolic"
        case .diastolic: return "diastolic"
        case .heartRate: return "heartRate"
        case .temperature: return "temperature"
        }
    }
}

#Preview {
    Group {
        NurseVitalsEntryView(patientId: "PAT001")
            .preferredColorScheme(.light)
    }
}
