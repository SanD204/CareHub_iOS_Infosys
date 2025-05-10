import SwiftUI
import FirebaseFirestore

struct ScheduleAppointmentView: View {
    let patientId: String
    let selectedSpecialty: String
    let selectedDoctor: String
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedDate = Date()
    @State private var selectedTimeSlot = ""
    @State private var isDatePickerExpanded = false
    @State private var description: String = ""
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var isDataLoaded = false
    @State private var isDataLoadFailed = false
    @State private var consultationFee: Double = 0.0
    
    private var timeSlots: [String] {
        var slots = [String]()
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        
        guard let startDate = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) else {
            return []
        }
        
        var currentDate = startDate
        while calendar.component(.hour, from: currentDate) < 18 {
            slots.append(dateFormatter.string(from: currentDate))
            guard let newDate = calendar.date(byAdding: .minute, value: 30, to: currentDate) else {
                break
            }
            currentDate = newDate
        }
        
        return slots
    }
    
    private func isTimeSlotAvailable(_ slot: String) -> Bool {
        if Calendar.current.isDateInToday(selectedDate) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            
            guard let slotTime = timeFormatter.date(from: slot) else {
                return false
            }
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: slotTime)
            
            guard let slotDateTime = calendar.date(
                bySettingHour: components.hour ?? 0,
                minute: components.minute ?? 0,
                second: 0,
                of: Date()
            ) else {
                return false
            }
            
            return slotDateTime > Date().addingTimeInterval(15 * 60)
        }
        
        return true
    }
    
    private let purpleColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    private let gradientColors = [
        Color(red: 0.43, green: 0.34, blue: 0.99),
        Color(red: 0.55, green: 0.48, blue: 0.99)
    ]
    
    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.94, blue: 1.0)
                .edgesIgnoringSafeArea(.all)
            
            if !isDataLoaded && !isDataLoadFailed {
                ProgressView()
                    .tint(purpleColor)
                    .padding()
            } else if isDataLoadFailed {
                VStack {
                    Text("Failed to load data")
                        .foregroundColor(.red)
                        .font(FontSizeManager.font(for: 18, weight: .medium))
                    Button(action: {
                        isDataLoaded = false
                        isDataLoadFailed = false
                        loadData()
                    }) {
                        Text("Retry")
                            .font(FontSizeManager.font(for: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding()
                            .background(purpleColor)
                            .cornerRadius(10)
                    }
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        
                        specialtySelectionSection
                        
                        doctorSelectionSection
                        
                        dateSelectionSection
                        
                        timeSlotSelectionSection
                        
                        descriptionField
                        
                        if !selectedTimeSlot.isEmpty {
                            confirmButtonSection
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 30)
                    .animation(.easeInOut(duration: 0.3), value: selectedTimeSlot)
                    .animation(.easeInOut(duration: 0.3), value: isDatePickerExpanded)
                }
            }
        }
        .navigationTitle("New Appointment")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Appointment Scheduled", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your appointment has been successfully scheduled.")
                .font(FontSizeManager.font(for: 16))
        }
        .alert("Cannot Schedule Appointment", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
                .font(FontSizeManager.font(for: 16))
        }
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        DoctorData.fetchDoctors {
            isDataLoaded = true
            if DoctorData.specialties.isEmpty {
                isDataLoadFailed = true
            } else {
                // Fetch consultation fee
                let doctor = DoctorData.doctors[selectedSpecialty]?.first { $0.doctor_name == selectedDoctor }
                consultationFee = Double(doctor?.consultationFee ?? Int(0.0))
            }
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Book Appointment")
                .font(FontSizeManager.font(for: 28, weight: .bold))
                .foregroundColor(.black)
            
            Text("Schedule with your preferred doctor")
                .font(FontSizeManager.font(for: 16))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var specialtySelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "stethoscope")
                    .font(.system(size: FontSizeManager.fontSize(for: 18)))
                    .foregroundColor(purpleColor)
                
                Text("Specialty")
                    .font(FontSizeManager.font(for: 18, weight: .medium))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 20)
            
            HStack {
                Text(selectedSpecialty)
                    .foregroundColor(.black)
                    .font(FontSizeManager.font(for: 16))
                
                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
            )
            .padding(.horizontal, 20)
        }
    }
    
    private var doctorSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.fill")
                    .font(.system(size: FontSizeManager.fontSize(for: 18)))
                    .foregroundColor(purpleColor)
                
                Text("Doctor")
                    .font(FontSizeManager.font(for: 18, weight: .medium))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 20)
            
            HStack {
                Text(selectedDoctor)
                    .foregroundColor(.black)
                    .font(FontSizeManager.font(for: 16))
                
                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
            )
            .padding(.horizontal, 20)
        }
    }
    
    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: FontSizeManager.fontSize(for: 18)))
                    .foregroundColor(purpleColor)
                
                Text("Date")
                    .font(FontSizeManager.font(for: 18, weight: .medium))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 20)
            
            VStack {
                if !isDatePickerExpanded {
                    Button(action: {
                        withAnimation {
                            isDatePickerExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Text(formattedDate(selectedDate))
                                .foregroundColor(.black)
                                .font(FontSizeManager.font(for: 16))
                            
                            Spacer()
                            
                            Image(systemName: "calendar")
                                .foregroundColor(purpleColor)
                                .font(.system(size: FontSizeManager.fontSize(for: 14)))
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                        )
                    }
                } else {
                    DatePicker(
                        "Select Date",
                        selection: Binding(
                            get: { selectedDate },
                            set: { newDate in
                                selectedDate = newDate
                                withAnimation {
                                    isDatePickerExpanded = false
                                }
                            }
                        ),
                        in: Date()...Calendar.current.date(byAdding: .month, value: 3, to: Date())!,
                        displayedComponents: .date
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .accentColor(purpleColor)
                    .padding(.top, 8)
                    .font(FontSizeManager.font(for: 16))
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var timeSlotSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.system(size: FontSizeManager.fontSize(for: 18)))
                    .foregroundColor(purpleColor)
                
                Text("Available Time Slots")
                    .font(FontSizeManager.font(for: 18, weight: .medium))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 20)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(purpleColor.opacity(0.8))
                        .font(.system(size: FontSizeManager.fontSize(for: 14)))
                    
                    Text(formattedDateWithDay(selectedDate))
                        .font(FontSizeManager.font(for: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(timeSlots, id: \.self) { slot in
                        Button(action: {
                            selectedTimeSlot = slot
                        }) {
                            Text(slot)
                                .font(FontSizeManager.font(for: 14, weight: .medium))
                                .foregroundColor(slotTextColor(for: slot))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    Group {
                                        if selectedTimeSlot == slot {
                                            LinearGradient(
                                                gradient: Gradient(colors: gradientColors),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                            .cornerRadius(10)
                                            .shadow(color: purpleColor.opacity(0.3), radius: 4, x: 0, y: 2)
                                        } else {
                                            Color.white
                                                .cornerRadius(10)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(slotBorderColor(for: slot), lineWidth: 1)
                                                )
                                        }
                                    }
                                )
                        }
                        .disabled(!isTimeSlotAvailable(slot))
                        .opacity(isTimeSlotAvailable(slot) ? 1.0 : 0.5)
                    }
                }
                .padding(16)
            }
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
            )
            .padding(.horizontal, 20)
        }
    }
    
    private func slotTextColor(for slot: String) -> Color {
        if !isTimeSlotAvailable(slot) {
            return .gray
        }
        return selectedTimeSlot == slot ? .white : purpleColor
    }
    
    private func slotBorderColor(for slot: String) -> Color {
        if !isTimeSlotAvailable(slot) {
            return Color.gray.opacity(0.3)
        }
        return purpleColor
    }
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "text.bubble")
                    .font(.system(size: FontSizeManager.fontSize(for: 18)))
                    .foregroundColor(purpleColor)
                
                Text("Description (Optional)")
                    .font(FontSizeManager.font(for: 18, weight: .medium))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 20)
            
            TextField("Brief description of your appointment", text: $description)
                .font(FontSizeManager.font(for: 16))
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                )
                .padding(.horizontal, 20)
        }
    }
    
    private var confirmButtonSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Appointment Summary")
                    .font(FontSizeManager.font(for: 18, weight: .semibold))
                    .foregroundColor(purpleColor)
                
                VStack(spacing: 14) {
                    summaryRow(icon: "stethoscope", title: "Specialty", value: selectedSpecialty)
                    summaryRow(icon: "person.fill", title: "Doctor", value: selectedDoctor)
                    summaryRow(icon: "calendar", title: "Date", value: formattedDate(selectedDate))
                    summaryRow(icon: "clock.fill", title: "Time", value: selectedTimeSlot)
                    summaryRow(icon: "dollarsign.circle", title: "Fees", value: String(format: "%.2f Rs", consultationFee))
                    if !description.isEmpty {
                        summaryRow(icon: "text.bubble", title: "Description", value: description)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.97, green: 0.97, blue: 1.0))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.9, green: 0.9, blue: 1.0), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 20)
            
            Button(action: {
                scheduleAppointment()
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Confirm Appointment")
                            .font(FontSizeManager.font(for: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: FontSizeManager.fontSize(for: 18)))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .cornerRadius(12)
                    .shadow(color: purpleColor.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .disabled(isLoading)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func summaryRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: FontSizeManager.fontSize(for: 14)))
                .foregroundColor(purpleColor)
                .frame(width: 20)
            
            Text(title)
                .font(FontSizeManager.font(for: 14, weight: .medium))
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(FontSizeManager.font(for: 14, weight: .semibold))
                .foregroundColor(.black)
                .lineLimit(1)
            
            Spacer()
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formattedDateWithDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func scheduleAppointment() {
        isLoading = true
        
        let calendar = Calendar.current
        let db = Firestore.firestore()
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        guard let timeDate = timeFormatter.date(from: selectedTimeSlot) else {
            isLoading = false
            errorMessage = "Invalid time format"
            showErrorAlert = true
            return
        }
        
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)
        guard let appointmentDateTime = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                                      minute: timeComponents.minute ?? 0,
                                                      second: 0,
                                                      of: selectedDate) else {
            isLoading = false
            errorMessage = "Could not create appointment date"
            showErrorAlert = true
            return
        }
        
        let doctor = DoctorData.doctors[selectedSpecialty]?.first { $0.doctor_name == selectedDoctor }
        let doctorId = doctor?.id ?? ""
        
        // Check for existing appointments at the same date and time slot
        db.collection("appointments")
            .whereField("patientId", isEqualTo: patientId)
            .whereField("date", isEqualTo: Timestamp(date: appointmentDateTime))
            .getDocuments { [self] (querySnapshot, error) in
                if let error = error {
                    errorMessage = "Error checking appointments: \(error.localizedDescription)"
                    showErrorAlert = true
                    isLoading = false
                    return
                }
                
                guard let documents = querySnapshot?.documents, documents.isEmpty else {
                    errorMessage = "You already have an appointment at this time slot. Please choose a different time."
                    showErrorAlert = true
                    isLoading = false
                    return
                }
                
                createNewAppointment(appointmentDateTime: appointmentDateTime, doctorId: doctorId)
            }
    }
    private func createNewAppointment(appointmentDateTime: Date, doctorId: String) {
        let randomNumber = Int.random(in: 0..<10000)
        let randomLetters = String(format: "%02X", Int.random(in: 0..<256))
        let appointmentId = "APT\(randomNumber)\(randomLetters)"
        
        let calendar = Calendar.current
        let doctor = DoctorData.doctors[selectedSpecialty]?.first { $0.doctor_name == selectedDoctor }
        let consultationFee = doctor?.consultationFee ?? 0
        
        let followUpDate = calendar.date(byAdding: .day, value: 7, to: appointmentDateTime) ?? Date()
        
        let appointmentData: [String: Any] = [
            "date": Timestamp(date: appointmentDateTime),
            "description": description.isEmpty ? "General Checkup" : description,
            "status": "scheduled",
            "apptId": appointmentId,
            "billingStatus": "pending",
            "docId": doctorId,
            "doctorsNotes": "",
            "followUpDate": Timestamp(date: followUpDate),
            "followUpRequired": false,
            "patientId": patientId,
            "prescriptionId": "",
            "amount": Double(consultationFee)
        ]
        
        let db = Firestore.firestore()
        db.collection("appointments").document(appointmentId).setData(appointmentData) { error in
            isLoading = false
            if let error = error {
                errorMessage = "Failed to schedule appointment: \(error.localizedDescription)"
                showErrorAlert = true
            } else {
                showSuccessAlert = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
