import SwiftUI
import FirebaseFirestore
import AVFoundation

struct DoctorView: View {
    let patientId: String
    @State private var specialties: [String] = []
    @State private var isDataLoaded = false
    @State private var isDataLoadFailed = false
    @State private var searchText = ""
    @State private var doctorNames: [String] = []
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    @AppStorage("isVoiceOverEnabled") private var isVoiceOverEnabled = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var isInitialLoad = true

    var filteredSpecialties: [String] {
        if searchText.isEmpty {
            return specialties
        } else {
            let searchTextLowercased = searchText.lowercased()
            var matchingSpecialties: Set<String> = []

            // Check if the search query matches a doctor's name
            let doctorMatches = doctorNames.filter { $0.lowercased().contains(searchTextLowercased) }
            if !doctorMatches.isEmpty {
                // If searching by doctor name, return empty specialties to show only doctor names
                return []
            }

            // Check for symptom matches
            for (symptom, specialties) in SymptomToSpecialtyData.symptomToSpecialty {
                if symptom.lowercased().contains(searchTextLowercased) {
                    matchingSpecialties.formUnion(specialties)
                }
            }

            // Check for direct specialty name matches
            let specialtyMatches = specialties.filter { specialty in
                specialty.lowercased().contains(searchTextLowercased)
            }
            matchingSpecialties.formUnion(specialtyMatches)

            return specialties.filter { specialty in
                matchingSpecialties.contains(specialty)
            }
        }
    }

    var filteredDoctorNames: [String] {
        if searchText.isEmpty {
            return []
        } else {
            let searchTextLowercased = searchText.lowercased()
            return doctorNames.filter { $0.lowercased().contains(searchTextLowercased) }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.94, green: 0.94, blue: 1.0)
                    .edgesIgnoringSafeArea(.all)
                if !isDataLoaded && !isDataLoadFailed {
                    ProgressView()
                        .tint(Color(red: 0.43, green: 0.34, blue: 0.99))
                        .padding()
                        .accessibilityLabel("Loading specialties")
                } else if isDataLoadFailed {
                    VStack {
                        Text("Failed to load specialties")
                            .foregroundColor(.red)
                            .font(FontSizeManager.font(for: 18, weight: .medium))
                            .accessibilityLabel("Failed to load specialties")
                        Button(action: {
                            isDataLoaded = false
                            isDataLoadFailed = false
                            loadData()
                        }) {
                            Text("Retry")
                                .font(FontSizeManager.font(for: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(red: 0.43, green: 0.34, blue: 0.99))
                                .cornerRadius(10)
                        }
                        .accessibilityLabel("Retry loading specialties")
                        .accessibilityHint("Tap to retry loading the specialties")
                    }
                    .padding()
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Error loading specialties")
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Search Bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                                    .font(.system(size: FontSizeManager.fontSize(for: 18)))
                                    .padding(.leading, 12)
                                    .accessibilityHidden(true)
                                
                                TextField("Search by symptom, specialty, or doctor name", text: $searchText)
                                    .font(FontSizeManager.font(for: 16))
                                    .padding(.vertical, 12)
                                    .accessibilityLabel("Search")
                                    .accessibilityHint(isVoiceOverEnabled ? "Enter a symptom, specialty, or doctor name to search" : "")
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Search bar")
                            
                            // Results Section
                            if !filteredDoctorNames.isEmpty {
                                // Doctor Names Section
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Matching Doctors")
                                        .font(FontSizeManager.font(for: 28, weight: .bold))
                                        .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                                        .padding(.horizontal, 16)
                                        .accessibilityAddTraits(.isHeader)
                                    
                                    ForEach(filteredDoctorNames, id: \.self) { doctorName in
                                        NavigationLink(destination: doctorDetailView(for: doctorName)) {
                                            HStack {
                                                Text(doctorName)
                                                    .font(FontSizeManager.font(for: 16, weight: .semibold))
                                                    .foregroundColor(.black)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                                                    .font(.system(size: FontSizeManager.fontSize(for: 14), weight: .semibold))
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 16)
                                            .background(Color.white)
                                            .cornerRadius(12)
                                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                                            .padding(.horizontal, 16)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .accessibilityLabel("Doctor: \(doctorName)")
                                        .accessibilityHint(isVoiceOverEnabled ? "Tap to view details for \(doctorName)" : "")
                                    }
                                }
                                .padding(.bottom, 24)
                            } else {
                                // Specialties Section
                                Text("Suggested Specialties")
                                    .font(FontSizeManager.font(for: 28, weight: .bold))
                                    .padding(.bottom, 8)
                                    .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                                    .accessibilityAddTraits(.isHeader)
                                
                                if filteredSpecialties.isEmpty && !searchText.isEmpty {
                                    Text("No specialties found for this symptom or specialty")
                                        .font(FontSizeManager.font(for: 16, weight: .medium))
                                        .foregroundColor(.gray)
                                        .padding(.vertical, 20)
                                        .accessibilityLabel("No specialties found")
                                } else {
                                    LazyVGrid(columns: columns, spacing: 16) {
                                        ForEach(filteredSpecialties, id: \.self) { specialty in
                                            NavigationLink(destination: SpecialtyDoctorsView(selectedSpecialty: specialty, patientId: patientId)) {
                                                SpecialtyCard(specialty: specialty)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .accessibilityLabel("Specialty: \(specialty)")
                                            .accessibilityHint(isVoiceOverEnabled ? "Tap to view doctors in \(specialty)" : "")
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 24)
                                }
                            }
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Doctor Search View")
                }
            }
            .onAppear {
                loadData()
                if isInitialLoad {
                    isInitialLoad = false
                } else if isVoiceOverEnabled {
                    readDoctorViewText()
                }
            }
            .onChange(of: isVoiceOverEnabled) { newValue in
                if newValue {
                    readDoctorViewText()
                } else {
                    speechSynthesizer.stopSpeaking(at: .immediate)
                }
            }
            .onChange(of: searchText) { _ in
                if isVoiceOverEnabled {
                    readDoctorViewText()
                }
            }
            .onDisappear {
                speechSynthesizer.stopSpeaking(at: .immediate)
            }
        }
    }

    private func loadData() {
        DoctorData.fetchDoctors {
            specialties = DoctorData.specialties
            doctorNames = DoctorData.doctors.values.flatMap { $0.map { $0.doctor_name } }
            isDataLoaded = true
            if specialties.isEmpty {
                isDataLoadFailed = true
            }
        }
    }

    private func readDoctorViewText() {
        var textToRead = "Doctor Search View. "
        if !searchText.isEmpty {
            if !filteredDoctorNames.isEmpty {
                textToRead += "Found \(filteredDoctorNames.count) matching doctors. "
            } else if !filteredSpecialties.isEmpty {
                textToRead += "Found \(filteredSpecialties.count) matching specialties. "
            } else {
                textToRead += "No results found. "
            }
        } else {
            textToRead += "Showing all specialties. "
        }
        speak(text: textToRead)
    }

    private func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        speechSynthesizer.speak(utterance)
    }

    private func doctorDetailView(for doctorName: String) -> some View {
        // Find the doctor and their specialty
        var doctor: Doctor?
        var specialty: String = ""
        for (spec, doctors) in DoctorData.doctors {
            if let foundDoctor = doctors.first(where: { $0.doctor_name == doctorName }) {
                doctor = foundDoctor
                specialty = spec
                break
            }
        }
        
        if let doctor = doctor {
            return AnyView(DoctorDetailView(doctor: doctor, specialty: specialty, patientId: patientId))
        } else {
            // Fallback in case doctor is not found (shouldn't happen with proper data)
            return AnyView(Text("Doctor not found").foregroundColor(.red))
        }
    }
}

// The rest of the code (SpecialtyCard, SpecialtyDoctorsView, DoctorCardView, DoctorDetailView) remains unchanged

struct SpecialtyCard: View {
    let specialty: String
    var iconName: String {
        switch specialty {
        case "Cardiology": return "heart.fill"
        case "Orthopedics": return "figure.walk"
        case "Neurology": return "brain.head.profile"
        case "Gynecology": return "person.crop.circle.fill"
        case "Surgery": return "scissors"
        case "Dermatology": return "hand.raised.fill"
        case "Endocrinology": return "chart.bar.fill"
        case "ENT": return "ear.fill"
        case "Oncology": return "waveform.path.ecg"
        case "Psychiatry": return "brain.fill"
        case "Urology": return "kidneys"
        case "Pediatrics": return "figure.2.and.child.holdinghands"
        default: return "stethoscope"
        }
    }
    
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: iconName)
                .font(.system(size: FontSizeManager.fontSize(for: 32)))
                .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                .frame(height: 36)
                .padding(.top, 8)
                .accessibilityHidden(true)
            
            Text(specialty)
                .font(FontSizeManager.font(for: 16, weight: .semibold))
                .foregroundColor(.black)
                .padding(.bottom, 10)
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .frame(height: 120)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

struct SpecialtyDoctorsView: View {
    let selectedSpecialty: String
    let patientId: String
    @State private var searchText = ""
    @State private var sortByExp = false
    @State private var doctors: [Doctor] = []
    @State private var isDataLoaded = false
    @State private var isDataLoadFailed = false
    @AppStorage("isVoiceOverEnabled") private var isVoiceOverEnabled = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()

    var filteredDoctors: [Doctor] {
        let filtered = doctors.filter { doctor in
            searchText.isEmpty || doctor.doctor_name.lowercased().contains(searchText.lowercased())
        }
        return sortByExp ? filtered.sorted { ($0.doctor_experience ?? 0) > ($1.doctor_experience ?? 0) } : filtered.sorted { ($0.doctor_experience ?? 0) < ($1.doctor_experience ?? 0) }
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.94, blue: 1.0)
                .edgesIgnoringSafeArea(.all)
            
            if !isDataLoaded && !isDataLoadFailed {
                ProgressView()
                    .tint(Color(red: 0.43, green: 0.34, blue: 0.99))
                    .padding()
                    .accessibilityLabel("Loading doctors")
            } else if isDataLoadFailed {
                VStack {
                    Text("Failed to load doctors")
                        .foregroundColor(.red)
                        .font(FontSizeManager.font(for: 18, weight: .medium))
                        .accessibilityLabel("Failed to load doctors")
                    Button(action: {
                        isDataLoaded = false
                        isDataLoadFailed = false
                        loadDoctors()
                    }) {
                        Text("Retry")
                            .font(FontSizeManager.font(for: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(red: 0.43, green: 0.34, blue: 0.99))
                            .cornerRadius(10)
                    }
                    .accessibilityLabel("Retry loading doctors")
                    .accessibilityHint("Tap to retry loading the doctors")
                }
                .padding()
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Error loading doctors")
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        HStack {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                                    .font(.system(size: FontSizeManager.fontSize(for: 18)))
                                    .padding(.leading, 12)
                                    .accessibilityHidden(true)
                                
                                TextField("Search by doctor name...", text: $searchText)
                                    .font(FontSizeManager.font(for: 16))
                                    .padding(.vertical, 12)
                                    .accessibilityLabel("Search doctors")
                                    .accessibilityHint(isVoiceOverEnabled ? "Enter a doctor name to search" : "")
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                            .padding(.leading, 16)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Search bar")
                            
                            Menu {
                                Button(action: { sortByExp = false }) {
                                    Text("Sort by Exp (Low to High)")
                                        .font(FontSizeManager.font(for: 14))
                                }
                                Button(action: { sortByExp = true }) {
                                    Text("Sort by Exp (High to Low)")
                                        .font(FontSizeManager.font(for: 14))
                                }
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                                    .font(.system(size: FontSizeManager.fontSize(for: 20)))
                                    .padding(.trailing, 16)
                                    .padding(.vertical, 12)
                            }
                            .accessibilityLabel("Sort options")
                            .accessibilityHint(isVoiceOverEnabled ? "Tap to sort doctors by experience" : "")
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                        .padding(.trailing, 16)
                        
                        HStack {
                            Text(selectedSpecialty)
                                .font(FontSizeManager.font(for: 18, weight: .bold))
                                .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                            
                            Text("(\(filteredDoctors.count))")
                                .font(FontSizeManager.font(for: 18, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(selectedSpecialty), \(filteredDoctors.count) doctors")
                        
                        LazyVStack(spacing: 0) {
                            ForEach(filteredDoctors, id: \.id) { doctor in
                                NavigationLink(destination: DoctorDetailView(doctor: doctor, specialty: selectedSpecialty, patientId: patientId)) {
                                    DoctorCardView(
                                        name: doctor.doctor_name,
                                        specialty: selectedSpecialty,
                                        experience: doctor.doctor_experience ?? 0,
                                        imageName: "person.circle.fill"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityLabel("Doctor: \(doctor.doctor_name), \(selectedSpecialty), \(doctor.doctor_experience ?? 0) years experience")
                                .accessibilityHint(isVoiceOverEnabled ? "Tap to view details for \(doctor.doctor_name)" : "")
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Specialty Doctors View")
            }
        }
        .navigationTitle(selectedSpecialty)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadDoctors()
            if isVoiceOverEnabled {
                readSpecialtyDoctorsText()
            }
        }
        .onChange(of: isVoiceOverEnabled) { newValue in
            if newValue {
                readSpecialtyDoctorsText()
            } else {
                speechSynthesizer.stopSpeaking(at: .immediate)
            }
        }
        .onChange(of: searchText) { _ in
            if isVoiceOverEnabled {
                readSpecialtyDoctorsText()
            }
        }
        .onDisappear {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    private func loadDoctors() {
        let filteredDoctors = DoctorData.doctors[selectedSpecialty] ?? []
        doctors = filteredDoctors
        isDataLoaded = true
        if doctors.isEmpty {
            isDataLoadFailed = true
        }
    }

    private func readSpecialtyDoctorsText() {
        let textToRead = "\(selectedSpecialty) Doctors View. Found \(filteredDoctors.count) doctors."
        let utterance = AVSpeechUtterance(string: textToRead)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        speechSynthesizer.speak(utterance)
    }
}

struct DoctorCardView: View {
    let name: String
    let specialty: String
    let experience: Int
    let imageName: String
    @AppStorage("isVoiceOverEnabled") private var isVoiceOverEnabled = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: FontSizeManager.fontSize(for: 50), height: FontSizeManager.fontSize(for: 50))
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
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(FontSizeManager.font(for: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text(specialty)
                    .font(FontSizeManager.font(for: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                HStack(spacing: 4) {
                    Image(systemName: "briefcase.fill")
                        .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                        .font(.system(size: FontSizeManager.fontSize(for: 12)))
                        .accessibilityHidden(true)
                    
                    Text("\(experience) yrs exp")
                        .font(FontSizeManager.font(for: 12, weight: .medium))
                        .foregroundColor(Color.black.opacity(0.7))
                }
            }
            .padding(.vertical, 4)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                .font(.system(size: FontSizeManager.fontSize(for: 14), weight: .semibold))
                .padding(.trailing, 8)
                .accessibilityHidden(true)
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
        .accessibilityElement(children: .combine)
    }
}

struct DoctorDetailView: View {
    let doctor: Doctor
    let specialty: String
    let patientId: String
    @State private var qualifications: [String] = ["MBBS", "MD - General Medicine", "DNB - Cardiology"]
    @AppStorage("isVoiceOverEnabled") private var isVoiceOverEnabled = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero Card with doctor info
                VStack {
                    HStack(alignment: .top, spacing: 20) {
                        // Left side - Image
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: FontSizeManager.fontSize(for: 100), height: FontSizeManager.fontSize(for: 100))
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
                            .shadow(color: Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.3), radius: 8, x: 0, y: 4)
                            .accessibilityHidden(true)
                        
                        // Right side - Details
                        VStack(alignment: .leading, spacing: 10) {
                            Text(doctor.doctor_name)
                                .font(FontSizeManager.font(for: 22, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text(specialty)
                                .font(FontSizeManager.font(for: 16, weight: .medium))
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "briefcase.fill")
                                    .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                                    .font(.system(size: FontSizeManager.fontSize(for: 14)))
                                    .accessibilityHidden(true)
                                
                                Text("\(doctor.doctor_experience ?? 0) years experience")
                                    .font(FontSizeManager.font(for: 14, weight: .medium))
                                    .foregroundColor(Color.black.opacity(0.7))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(20)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Doctor: \(doctor.doctor_name), \(specialty), \(doctor.doctor_experience ?? 0) years experience")
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Qualifications Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Qualifications")
                        .font(FontSizeManager.font(for: 20, weight: .bold))
                        .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                        .padding(.horizontal, 16)
                        .accessibilityAddTraits(.isHeader)
                    
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(qualifications, id: \.self) { qualification in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                                    .font(.system(size: FontSizeManager.fontSize(for: 16)))
                                    .accessibilityHidden(true)
                                
                                Text(qualification)
                                    .font(FontSizeManager.font(for: 16))
                                    .foregroundColor(.black)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Qualification: \(qualification)")
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                    .padding(.horizontal, 16)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Qualifications Section")
                }
                
                // Book appointment button
                NavigationLink(destination: ScheduleAppointmentView(
                    patientId: patientId,
                    selectedSpecialty: specialty,
                    selectedDoctor: doctor.doctor_name
                )) {
                    HStack {
                        Spacer()
                        Text("Book Appointment")
                            .font(FontSizeManager.font(for: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                        Spacer()
                    }
                    .background(Color(red: 0.43, green: 0.34, blue: 0.99))
                    .cornerRadius(12)
                    .shadow(color: Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.4), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Book Appointment")
                .accessibilityHint(isVoiceOverEnabled ? "Tap to schedule an appointment with \(doctor.doctor_name)" : "")
            }
        }
        .background(Color(red: 0.94, green: 0.94, blue: 1.0))
        .navigationTitle("Doctor Profile")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Doctor Profile View")
        .onAppear {
            if isVoiceOverEnabled {
                let textToRead = "Doctor Profile for \(doctor.doctor_name), \(specialty). \(doctor.doctor_experience ?? 0) years experience."
                let utterance = AVSpeechUtterance(string: textToRead)
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                utterance.rate = 0.5
                speechSynthesizer.speak(utterance)
            }
        }
        .onDisappear {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }
}
