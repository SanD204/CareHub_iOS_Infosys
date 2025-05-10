////import SwiftUI
////import FirebaseFirestore
////import FirebaseAuth
////
////struct DoctorDashboardView: View {
////    @StateObject private var authManager = AuthManager.shared
////    @State private var selectedDate = Date()
////    @State private var viewMode: CalendarViewMode = .day
////    @State private var appointments: [Appointment] = []
////    @State private var doctorName: String = "Doctor"
////    @State private var doctorId: String = ""
////    @State private var showPatientProfileView = false
////    @State private var selectedPatientId: String? = nil
////    
////    @Environment(\.colorScheme) private var colorScheme
////    
////    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
////    private let secondaryColor = Color(red: 0.55, green: 0.48, blue: 0.99)
////    private let backgroundColor = Color(red: 0.97, green: 0.97, blue: 1.0)
////    private let cardBackground = Color.white
////    private let forNowColor = Color(red: 0.51, green: 0.44, blue: 0.87)
////    
////    private let db = Firestore.firestore()
////    
////    var body: some View {
////        ZStack {
////            backgroundColor.edgesIgnoringSafeArea(.all)
////            
////            VStack(spacing: 0) {
////                // Header
////                HStack {
////                    VStack(alignment: .leading, spacing: 6) {
////                        Text("Welcome, \(doctorName)")
////                            .font(.system(.title2, design: .rounded, weight: .bold))
////                            .foregroundColor(.primary)
////                        Text("Today's Overview")
////                            .font(.system(.subheadline, design: .rounded))
////                            .foregroundColor(.secondary)
////                    }
////                    Spacer()
////                }
////                .padding(.horizontal, 20)
////                .padding(.vertical, 16)
////                
////                // Main Content
////                switch viewMode {
////                case .month:
////                    MonthView(selectedDate: $selectedDate, viewMode: $viewMode)
////                case .day:
////                    DayView(
////                        selectedDate: $selectedDate,
////                        appointments: appointments.filter { $0.date?.isSameDay(as: selectedDate) ?? false },
////                        showPatientProfileView: $showPatientProfileView,
////                        selectedPatientId: $selectedPatientId
////                    )
////                }
////            }
////        }
////        .onAppear {
////            updateDoctorData()
////        }
////        .onReceive(authManager.$currentStaffMember) { _ in
////            updateDoctorData()
////        }
////        .navigationDestination(isPresented: $showPatientProfileView) {
////            if let patientId = selectedPatientId {
////                PatientProfileView(
////                    patientIdentifier: patientId,
////                    doctorId: doctorId,
////                    doctorName: doctorName
////                )
////            }
////        }
////    }
////    
////    private func updateDoctorData() {
////        if let staff = authManager.currentDoctor {
////            doctorName = staff.doctor_name
////            doctorId = staff.id ?? ""
////            guard let uid = Auth.auth().currentUser?.uid else {
////                doctorId = ""
////                doctorName = "Doctor"
////                appointments = []
////                return
////            }
////            
////            db.collection("doctors").document(uid).getDocument { snapshot, error in
////                if let error = error {
////                    print("Error fetching doctor: \(error.localizedDescription)")
////                    return
////                }
////                
////                guard let data = snapshot?.data(), snapshot?.exists == true,
////                      let docId = data["Doctorid"] as? String,
////                      let name = data["Doctor_name"] as? String else {
////                    doctorId = ""
////                    doctorName = "Doctor"
////                    appointments = []
////                    return
////                }
////                
////                doctorId = docId
////                doctorName = name
////                fetchData()
////            }
////        } else {
////            doctorName = "Doctor"
////            doctorId = ""
////            appointments = []
////        }
////    }
////    
////    private func fetchData() {
////        guard !doctorId.isEmpty else {
////            appointments = []
////            return
////        }
////        
////        db.collection("appointments")
////            .whereField("docId", isEqualTo: doctorId)
////            .getDocuments { snapshot, error in
////                if let error = error {
////                    print("Error fetching appointments: \(error)")
////                    return
////                }
////                
////                guard let documents = snapshot?.documents else {
////                    print("No appointment documents found for docId: \(doctorId)")
////                    appointments = []
////                    return
////                }
////                
////                appointments = documents.compactMap { doc -> Appointment? in
////                    let data = doc.data()
////                    print("Appointment document data: \(data)")
////                    
////                    guard let apptId = data["apptId"] as? String,
////                          let patientId = data["patientId"] as? String,
////                          let docId = data["docId"] as? String,
////                          let description = (data["description"] as? String) ?? (data["Description"] as? String),
////                          let status = (data["status"] as? String) ?? (data["Status"] as? String) else {
////                        print("Failed to map document: \(doc.documentID), missing required fields")
////                        return nil
////                    }
////                    
////                    let appointment = Appointment(
////                        id: doc.documentID,
////                        apptId: apptId,
////                        patientId: patientId,
////                        description: description,
////                        docId: docId,
////                        status: status.lowercased(),
////                        billingStatus: data["billingStatus"] as? String ?? "",
////                        amount: data["amount"] as? Double,
////                        date: (data["date"] as? Timestamp)?.dateValue(),
////                        doctorsNotes: (data["doctorsNotes"] as? String) ?? (data["doctorNotes"] as? String),
////                        prescriptionId: data["prescriptionId"] as? String,
////                        followUpRequired: data["followUpRequired"] as? Bool,
////                        followUpDate: (data["followUpDate"] as? Timestamp)?.dateValue()
////                    )
////                    print("Mapped appointment: \(appointment)")
////                    return appointment
////                }
////                print("Total appointments fetched: \(appointments.count)")
////            }
////    }
////}
////
////struct DayView: View {
////    @Binding var selectedDate: Date
////    let appointments: [Appointment]
////    @Binding var showPatientProfileView: Bool
////    @Binding var selectedPatientId: String?
////    
////    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
////    private let cardBackground = Color.white
////    private let backgroundColor = Color(red: 0.97, green: 0.97, blue: 1.0)
////    
////    var scheduleTitle: String {
////        let calendar = Calendar.current
////        let today = calendar.startOfDay(for: Date())
////        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
////        
////        if calendar.isDate(selectedDate, inSameDayAs: today) {
////            return "Today's Schedule"
////        } else if calendar.isDate(selectedDate, inSameDayAs: tomorrow) {
////            return "Tomorrow's Schedule"
////        } else {
////            return "Upcoming Schedule"
////        }
////    }
////    
////    var body: some View {
////        VStack(spacing: 0) {
////            // Calendar Week View
////            WeekScrollerView(selectedDate: $selectedDate)
////            
////            ScrollView {
////                VStack(spacing: 12) {
////                    Text(scheduleTitle)
////                        .font(.system(.title2, design: .rounded, weight: .bold))
////                        .frame(maxWidth: .infinity, alignment: .leading)
////                        .padding(.horizontal, 20)
////                        .padding(.top, 24)
////                    
////                    if appointments.isEmpty {
////                        VStack(spacing: 12) {
////                            Image(systemName: "calendar.badge.exclamationmark")
////                                .font(.system(size: 40))
////                                .foregroundColor(.gray)
////                            Text("No appointments scheduled")
////                                .font(.system(.body, design: .rounded))
////                                .foregroundColor(.gray)
////                        }
////                        .frame(maxWidth: .infinity)
////                        .padding(.vertical, 60)
////                        .background(backgroundColor)
////                        .cornerRadius(16)
////                        .padding(.horizontal, 20)
////                        .padding(.top, 12)
////                    } else {
////                        ForEach(appointments, id: \.id) { appointment in
////                            AppointmentView(
////                                appointment: appointment,
////                                showPatientProfileView: $showPatientProfileView,
////                                selectedPatientId: $selectedPatientId
////                            )
////                            .padding(.horizontal, 20)
////                        }
////                    }
////                }
////                .padding(.bottom, 20)
////            }
////        }
////    }
////}
////
////struct WeekScrollerView: View {
////    @Binding var selectedDate: Date
////    @State private var showDatePicker = false
////    private let calendar = Calendar.current
////    
////    private var weekStartDate: Date {
////        let today = calendar.startOfDay(for: Date())
////        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)) ?? today
////    }
////    
////    private var weekDates: [Date] {
////        (0..<7).compactMap { day in
////            calendar.date(byAdding: .day, value: day, to: weekStartDate)
////        }
////    }
////    
////    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
////    private let cardBackground = Color.white
////    
////    var body: some View {
////        HStack {
////            Spacer()
////            ZStack {
////                RoundedRectangle(cornerRadius: 16)
////                    .fill(cardBackground)
////                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
////                
////                VStack(spacing: 8) {
////                    HStack {
////                        Button(action: { moveWeek(by: -1) }) {
////                            Image(systemName: "chevron.left")
////                                .foregroundColor(primaryColor)
////                                .padding(8)
////                        }
////                        
////                        Spacer()
////                        
////                        Text(monthYearString(from: selectedDate))
////                            .font(.title3)
////                            .fontWeight(.bold)
////                            .onTapGesture {
////                                showDatePicker = true
////                            }
////                        
////                        Spacer()
////                        
////                        Button(action: { moveWeek(by: 1) }) {
////                            Image(systemName: "chevron.right")
////                                .foregroundColor(primaryColor)
////                                .padding(8)
////                        }
////                    }
////                    .padding(.horizontal, 8)
////                    .padding(.top, 12)
////                    
////                    HStack(spacing: 1) {
////                        ForEach(weekDates, id: \.self) { date in
////                            WeekDayCell(
////                                date: date,
////                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
////                                isToday: calendar.isDateInToday(date)
////                            )
////                            .onTapGesture {
////                                withAnimation {
////                                    selectedDate = date
////                                }
////                            }
////                        }
////                    }
////                    .padding(.bottom, 10)
////                }
////            }
////            .frame(width: UIScreen.main.bounds.width - 32, height: 120)
////            Spacer()
////        }
////        .sheet(isPresented: $showDatePicker) {
////            DatePicker(
////                "Select Date",
////                selection: $selectedDate,
////                displayedComponents: .date
////            )
////            .datePickerStyle(.graphical)
////            .presentationDetents([.medium])
////            .padding()
////        }
////    }
////    
////    private func moveWeek(by weeks: Int) {
////        if let newDate = calendar.date(byAdding: .weekOfYear, value: weeks, to: weekStartDate) {
////            withAnimation {
////                selectedDate = newDate
////            }
////        }
////    }
////    
////    private func monthYearString(from date: Date) -> String {
////        let formatter = DateFormatter()
////        formatter.dateFormat = "MMMM yyyy"
////        return formatter.string(from: date)
////    }
////}
////
////struct WeekDayCell: View {
////    let date: Date
////    let isSelected: Bool
////    let isToday: Bool
////    
////    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
////    
////    private var dayName: String {
////        let formatter = DateFormatter()
////        formatter.dateFormat = "E"
////        return formatter.string(from: date)
////    }
////    
////    private var dayNumber: String {
////        let formatter = DateFormatter()
////        formatter.dateFormat = "d"
////        return formatter.string(from: date)
////    }
////    
////    var body: some View {
////        VStack(spacing: 8) {
////            Text(dayName)
////                .font(.caption)
////                .foregroundColor(.gray)
////            
////            Text(dayNumber)
////                .font(.title3.weight(.semibold))
////                .frame(width: 32, height: 32)
////                .background(
////                    Circle()
////                        .fill(isSelected ? primaryColor : Color.clear)
////                        .overlay(
////                            Circle()
////                                .stroke(isToday && !isSelected ? primaryColor : Color.clear, lineWidth: 1.5)
////                        )
////                )
////                .foregroundColor(isSelected ? .white : (isToday ? primaryColor : .primary))
////        }
////        .frame(width: 50, height: 60)
////    }
////}
////
////struct AppointmentView: View {
////    let appointment: Appointment
////    @State private var patientName: String = "Unknown"
////    @Binding var showPatientProfileView: Bool
////    @Binding var selectedPatientId: String?
////    
////    private let db = Firestore.firestore()
////    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
////    private let secondaryColor = Color(red: 0.55, green: 0.48, blue: 0.99)
////    private let cardBackground = Color.white
////    private let forNowColor = Color(red: 0.51, green: 0.44, blue: 0.87)
////    
////    var body: some View {
////        Button(action: {
////            selectedPatientId = appointment.patientId
////            showPatientProfileView = true
////        }) {
////            VStack(alignment: .leading, spacing: 8) {
////                HStack {
////                    Circle()
////                        .fill(statusColor)
////                        .frame(width: 12, height: 12)
////                    
////                    Text(patientName)
////                        .font(.system(.headline, design: .rounded, weight: .bold))
////                        .foregroundColor(.primary)
////                    
////                    Spacer()
////                    
////                    Text(appointment.date?.formatted(.dateTime.hour().minute()) ?? "N/A")
////                        .font(.system(.subheadline, design: .rounded))
////                        .foregroundColor(.secondary)
////                }
////                
////                HStack {
////                    Text(appointment.status.capitalized)
////                        .font(.system(.caption, design: .rounded, weight: .medium))
////                        .padding(.vertical, 4)
////                        .padding(.horizontal, 8)
////                        .background(statusColor.opacity(0.2))
////                        .foregroundColor(statusColor)
////                        .overlay(
////                            Capsule()
////                                .stroke(forNowColor, lineWidth: 1)
////                        )
////                        .clipShape(Capsule())
////                    
//////                    if appointment.followUpRequired ?? false {
//////                        Image(systemName: "arrow.clockwise")
//////                            .font(.system(size: 12))
//////                            .foregroundColor(forNowColor)
//////                    }
////                }
////                
////                if !appointment.description.isEmpty {
////                    Text(appointment.description)
////                        .font(.system(.subheadline, design: .rounded))
////                        .foregroundColor(.secondary)
////                        .lineLimit(2)
////                }
////            }
////            .padding(16)
////            .background(cardBackground)
////            .clipShape(RoundedRectangle(cornerRadius: 12))
////            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
////            .scaleEffect(showPatientProfileView ? 0.98 : 1.0)
////            .animation(.easeInOut(duration: 0.2), value: showPatientProfileView)
////        }
////        .onAppear {
////            fetchPatientName()
////        }
////    }
////    
////    private var statusColor: Color {
////        switch appointment.status.lowercased() {
////        case "cancelled":
////            return .red
////        case "scheduled":
////            return .orange
////        case "completed":
////            return .green
////        default:
////            return .gray
////        }
////    }
////    
////    private func fetchPatientName() {
////        db.collection("patients")
////            .whereField("patientId", isEqualTo: appointment.patientId)
////            .getDocuments { snapshot, error in
////                if let error = error {
////                    print("Error fetching patient: \(error)")
////                    return
////                }
////                
////                guard let documents = snapshot?.documents, !documents.isEmpty else {
////                    print("No patient found for patientId: \(appointment.patientId)")
////                    patientName = "Unknown"
////                    return
////                }
////                
////                if let data = documents.first?.data(),
////                   let userData = data["userData"] as? [String: Any],
////                   let name = userData["Name"] as? String {
////                    patientName = name
////                    print("Patient name fetched: \(name) for patientId: \(appointment.patientId)")
////                } else {
////                    print("Failed to fetch patient name for patientId: \(appointment.patientId)")
////                    patientName = "Unknown"
////                }
////            }
////    }
////}
////
////struct MonthView: View {
////    @Binding var selectedDate: Date
////    @Binding var viewMode: CalendarViewMode
////    
////    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
////    private let cardBackground = Color.white
////    
////    var body: some View {
////        HStack {
////            Spacer()
////            VStack(spacing: 8) {
////                MonthHeaderView(selectedDate: $selectedDate)
////                CalendarGridView(selectedDate: $selectedDate, viewMode: $viewMode)
////            }
////            .padding(12)
////            .background(cardBackground)
////            .clipShape(RoundedRectangle(cornerRadius: 16))
////            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
////            .frame(width: 320)
////            Spacer()
////        }
////        .padding(.horizontal, 12)
////    }
////}
////
////struct MonthHeaderView: View {
////    @Binding var selectedDate: Date
////    
////    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
////    
////    var body: some View {
////        HStack {
////            Button(action: { changeMonth(by: -1) }) {
////                Image(systemName: "chevron.left")
////                    .foregroundColor(primaryColor)
////                    .padding(8)
////            }
////            
////            Spacer()
////            
////            Text(selectedDate.formatted(.dateTime.month(.wide).year()))
////                .font(.title2.weight(.bold))
////                .foregroundColor(.primary)
////            
////            Spacer()
////            
////            Button(action: { changeMonth(by: 1) }) {
////                Image(systemName: "chevron.right")
////                    .foregroundColor(primaryColor)
////                    .padding(8)
////            }
////        }
////        .padding(.horizontal, 8)
////    }
////    
////    private func changeMonth(by value: Int) {
////        selectedDate = Calendar.current.date(byAdding: .month, value: value, to: selectedDate)!
////    }
////}
////
////struct CalendarGridView: View {
////    @Binding var selectedDate: Date
////    @Binding var viewMode: CalendarViewMode
////    
////    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
////    let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
////    
////    var daysInMonth: [Date] {
////        let calendar = Calendar.current
////        let range = calendar.range(of: .day, in: .month, for: selectedDate)!
////        let components = calendar.dateComponents([.year, .month], from: selectedDate)
////        
////        return range.compactMap { day -> Date? in
////            var newComponents = components
////            newComponents.day = day
////            return calendar.date(from: newComponents)
////        }
////    }
////    
////    var firstWeekday: Int {
////        let calendar = Calendar.current
////        let components = calendar.dateComponents([.year, .month], from: selectedDate)
////        let firstDay = calendar.date(from: components)!
////        return calendar.component(.weekday, from: firstDay)
////    }
////    
////    var body: some View {
////        VStack(spacing: 4) {
////            LazyVGrid(columns: columns, spacing: 4) {
////                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { weekday in
////                    Text(weekday)
////                        .font(.system(.caption, design: .rounded, weight: .medium))
////                        .foregroundColor(.secondary)
////                        .frame(maxWidth: .infinity)
////                }
////            }
////            
////            LazyVGrid(columns: columns, spacing: 4) {
////                ForEach(0..<firstWeekday-1, id: \.self) { _ in
////                    Color.clear
////                }
////                
////                ForEach(daysInMonth, id: \.self) { date in
////                    DayCell(date: date, selectedDate: $selectedDate, viewMode: $viewMode)
////                }
////            }
////        }
////        .padding(.horizontal, 8)
////        .padding(.bottom, 8)
////    }
////}
////
////struct DayCell: View {
////    let date: Date
////    @Binding var selectedDate: Date
////    @Binding var viewMode: CalendarViewMode
////    
////    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
////    
////    var body: some View {
////        Button(action: {
////            selectedDate = date
////            viewMode = .day
////        }) {
////            Text(date.formatted(.dateTime.day()))
////                .font(.system(.subheadline, design: .rounded, weight: .medium))
////                .foregroundColor(date.isSameDay(as: Date()) ? primaryColor : .primary)
////                .frame(width: 32, height: 32)
////                .background(date.isSameDay(as: selectedDate) ? primaryColor : Color.clear)
////                .foregroundColor(date.isSameDay(as: selectedDate) ? .white : .primary)
////                .clipShape(Circle())
////        }
////    }
////}
////
////enum CalendarViewMode {
////    case month, day
////}
////
////extension Date {
////    func isSameDay(as other: Date) -> Bool {
////        Calendar.current.isDate(self, inSameDayAs: other)
////    }
////}
////
////extension Color {
////    static let customButton = Color(red: 0.43, green: 0.34, blue: 0.99)
////    static let customCard = Color.white
////}
////
////struct DoctorDashboardView_Previews: PreviewProvider {
////    static var previews: some View {
////        DoctorDashboardView()
////    }
////}
//import SwiftUI
//import FirebaseFirestore
//import FirebaseAuth
//
//struct DoctorDashboardView: View {
//    @StateObject private var authManager = AuthManager.shared
//    @State private var selectedDate = Date()
//    @State private var viewMode: CalendarViewMode = .day
//    @State private var appointments: [Appointment] = []
//    @State private var doctorName: String = "Doctor"
//    @State private var doctorId: String = ""
//    @State private var showPatientProfileView = false
//    @State private var selectedPatientId: String? = nil
//    @State private var selectedApptId: String? = nil
//    
//    @Environment(\.colorScheme) private var colorScheme
//    
//    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
//    private let secondaryColor = Color(red: 0.55, green: 0.48, blue: 0.99)
//    private let backgroundColor = Color(red: 0.97, green: 0.97, blue: 1.0)
//    private let cardBackground = Color.white
//    private let forNowColor = Color(red: 0.51, green: 0.44, blue: 0.87)
//    
//    private let db = Firestore.firestore()
//    
//    var body: some View {
//        ZStack {
//            backgroundColor.edgesIgnoringSafeArea(.all)
//            
//            VStack(spacing: 0) {
//                // Header
//                HStack {
//                    VStack(alignment: .leading, spacing: 6) {
//                        Text("Welcome, \(doctorName)")
//                            .font(.system(.title2, design: .rounded, weight: .bold))
//                            .foregroundColor(.primary)
//                        Text("Today's Overview")
//                            .font(.system(.subheadline, design: .rounded))
//                            .foregroundColor(.secondary)
//                    }
//                    Spacer()
//                }
//                .padding(.horizontal, 20)
//                .padding(.vertical, 16)
//                
//                // Main Content
//                switch viewMode {
//                case .month:
//                    MonthView(selectedDate: $selectedDate, viewMode: $viewMode)
//                case .day:
//                    DayView(
//                        selectedDate: $selectedDate,
//                        appointments: appointments.filter { $0.date?.isSameDay(as: selectedDate) ?? false },
//                        showPatientProfileView: $showPatientProfileView,
//                        selectedPatientId: $selectedPatientId,
//                        selectedApptId: $selectedApptId
//                    )
//                }
//            }
//        }
//        .onAppear {
//            updateDoctorData()
//        }
//        .onReceive(authManager.$currentStaffMember) { _ in
//            updateDoctorData()
//        }
//        .navigationDestination(isPresented: $showPatientProfileView) {
//                if let patientId = selectedPatientId, let apptId = selectedApptId {
//                    PatientProfileView(
//                        patientIdentifier: patientId,
//                        doctorId: doctorId,
//                        doctorName: doctorName,
//                        apptId: apptId // Pass the apptId
//                )
//            }
//        }
//    }
//    
//    private func updateDoctorData() {
//        if let staff = authManager.currentDoctor {
//            doctorName = staff.doctor_name
//            doctorId = staff.id ?? ""
//            guard let uid = Auth.auth().currentUser?.uid else {
//                doctorId = ""
//                doctorName = "Doctor"
//                appointments = []
//                return
//            }
//            
//            db.collection("doctors").document(uid).getDocument { snapshot, error in
//                if let error = error {
//                    print("Error fetching doctor: \(error.localizedDescription)")
//                    return
//                }
//                
//                guard let data = snapshot?.data(), snapshot?.exists == true,
//                      let docId = data["Doctorid"] as? String,
//                      let name = data["Doctor_name"] as? String else {
//                    doctorId = ""
//                    doctorName = "Doctor"
//                    appointments = []
//                    return
//                }
//                
//                doctorId = docId
//                doctorName = name
//                fetchData()
//            }
//        } else {
//            doctorName = "Doctor"
//            doctorId = ""
//            appointments = []
//        }
//    }
//    
//    private func fetchData() {
//        guard !doctorId.isEmpty else {
//            appointments = []
//            return
//        }
//        
//        db.collection("appointments")
//            .whereField("docId", isEqualTo: doctorId)
//            .getDocuments { snapshot, error in
//                if let error = error {
//                    print("Error fetching appointments: \(error)")
//                    return
//                }
//                
//                guard let documents = snapshot?.documents else {
//                    print("No appointment documents found for docId: \(doctorId)")
//                    appointments = []
//                    return
//                }
//                
//                appointments = documents.compactMap { doc -> Appointment? in
//                    let data = doc.data()
//                    print("Appointment document data: \(data)")
//                    
//                    guard let apptId = data["apptId"] as? String,
//                          let patientId = data["patientId"] as? String,
//                          let docId = data["docId"] as? String,
//                          let description = (data["description"] as? String) ?? (data["Description"] as? String),
//                          let status = (data["status"] as? String) ?? (data["Status"] as? String) else {
//                        print("Failed to map document: \(doc.documentID), missing required fields")
//                        return nil
//                    }
//                    
//                    let appointment = Appointment(
//                        id: doc.documentID,
//                        apptId: apptId,
//                        patientId: patientId,
//                        description: description,
//                        docId: docId,
//                        status: status.lowercased(),
//                        billingStatus: data["billingStatus"] as? String ?? "",
//                        amount: data["amount"] as? Double,
//                        date: (data["date"] as? Timestamp)?.dateValue(),
//                        doctorsNotes: (data["doctorsNotes"] as? String) ?? (data["doctorNotes"] as? String),
//                        prescriptionId: data["prescriptionId"] as? String,
//                        followUpRequired: data["followUpRequired"] as? Bool,
//                        followUpDate: (data["followUpDate"] as? Timestamp)?.dateValue()
//                    )
//                    print("Mapped appointment: \(appointment)")
//                    return appointment
//                }
//                .sorted { (appt1, appt2) -> Bool in
//                    guard let date1 = appt1.date, let date2 = appt2.date else {
//                        return false
//                    }
//                    return date1 < date2
//                }
//                
//                print("Total appointments fetched: \(appointments.count)")
//            }
//    }
//}
//
//struct DayView: View {
//    @Binding var selectedDate: Date
//    let appointments: [Appointment]
//    @Binding var showPatientProfileView: Bool
//    @Binding var selectedPatientId: String?
//    @Binding var selectedApptId: String?
//
//    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
//    private let cardBackground = Color.white
//    private let backgroundColor = Color(red: 0.97, green: 0.97, blue: 1.0)
//
//    var scheduleTitle: String {
//        let calendar = Calendar.current
//        let today = calendar.startOfDay(for: Date())
//        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
//
//        if calendar.isDate(selectedDate, inSameDayAs: today) {
//            return "Today's Schedule"
//        } else if calendar.isDate(selectedDate, inSameDayAs: tomorrow) {
//            return "Tomorrow's Schedule"
//        } else {
//            return "Upcoming Schedule"
//        }
//    }
//
//    // Sort appointments to move "completed" to the bottom
//    private var sortedAppointments: [Appointment] {
//        appointments.sorted { appt1, appt2 in
//            if appt1.status.lowercased() == "completed" && appt2.status.lowercased() != "completed" {
//                return false // appt1 (completed) goes after appt2
//            } else if appt1.status.lowercased() != "completed" && appt2.status.lowercased() == "completed" {
//                return true // appt1 (non-completed) goes before appt2
//            } else {
//                // If both are completed or both are non-completed, maintain date order
//                guard let date1 = appt1.date, let date2 = appt2.date else {
//                    return false
//                }
//                return date1 < date2
//            }
//        }
//    }
//
//    var body: some View {
//        VStack(spacing: 0) {
//            // Calendar Week View
//            WeekScrollerView(selectedDate: $selectedDate)
//
//            ScrollView {
//                VStack(spacing: 12) {
//                    Text(scheduleTitle)
//                        .font(.system(.title2, design: .rounded, weight: .bold))
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .padding(.horizontal, 20)
//                        .padding(.top, 24)
//
//                    if sortedAppointments.isEmpty {
//                        VStack(spacing: 12) {
//                            Image(systemName: "calendar.badge.exclamationmark")
//                                .font(.system(size: 40))
//                                .foregroundColor(.gray)
//                            Text("No appointments scheduled")
//                                .font(.system(.body, design: .rounded))
//                                .foregroundColor(.gray)
//                        }
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 60)
//                        .background(backgroundColor)
//                        .cornerRadius(16)
//                        .padding(.horizontal, 20)
//                        .padding(.top, 12)
//                    } else {
//                        ForEach(sortedAppointments, id: \.id) { appointment in
//                            AppointmentView(
//                                appointment: appointment,
//                                showPatientProfileView: $showPatientProfileView,
//                                selectedPatientId: $selectedPatientId,
//                                selectedApptId: $selectedApptId
//                            )
//                            .padding(.horizontal, 20)
//                        }
//                    }
//                }
//                .padding(.bottom, 20)
//            }
//        }
//    }
//}
//
//struct WeekScrollerView: View {
//    @Binding var selectedDate: Date
//    @State private var showDatePicker = false
//    private let calendar = Calendar.current
//    
//    private var weekStartDate: Date {
//        let today = calendar.startOfDay(for: Date())
//        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)) ?? today
//    }
//    
//    private var weekDates: [Date] {
//        (0..<7).compactMap { day in
//            calendar.date(byAdding: .day, value: day, to: weekStartDate)
//        }
//    }
//    
//    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
//    private let cardBackground = Color.white
//    
//    var body: some View {
//        HStack {
//            Spacer()
//            ZStack {
//                RoundedRectangle(cornerRadius: 16)
//                    .fill(cardBackground)
//                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
//                
//                VStack(spacing: 8) {
//                    HStack {
//                        Button(action: { moveWeek(by: -1) }) {
//                            Image(systemName: "chevron.left")
//                                .foregroundColor(primaryColor)
//                                .padding(8)
//                        }
//                        
//                        Spacer()
//                        
//                        Text(monthYearString(from: selectedDate))
//                            .font(.title3)
//                            .fontWeight(.bold)
//                            .onTapGesture {
//                                showDatePicker = true
//                            }
//                        
//                        Spacer()
//                        
//                        Button(action: { moveWeek(by: 1) }) {
//                            Image(systemName: "chevron.right")
//                                .foregroundColor(primaryColor)
//                                .padding(8)
//                        }
//                    }
//                    .padding(.horizontal, 8)
//                    .padding(.top, 12)
//                    
//                    HStack(spacing: 1) {
//                        ForEach(weekDates, id: \.self) { date in
//                            WeekDayCell(
//                                date: date,
//                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
//                                isToday: calendar.isDateInToday(date)
//                            )
//                            .onTapGesture {
//                                withAnimation {
//                                    selectedDate = date
//                                }
//                            }
//                        }
//                    }
//                    .padding(.bottom, 10)
//                }
//            }
//            .frame(width: UIScreen.main.bounds.width - 32, height: 120)
//            Spacer()
//        }
//        .sheet(isPresented: $showDatePicker) {
//            DatePicker(
//                "Select Date",
//                selection: $selectedDate,
//                displayedComponents: .date
//            )
//            .datePickerStyle(.graphical)
//            .presentationDetents([.medium])
//            .padding()
//        }
//    }
//    
//    private func moveWeek(by weeks: Int) {
//        if let newDate = calendar.date(byAdding: .weekOfYear, value: weeks, to: weekStartDate) {
//            withAnimation {
//                selectedDate = newDate
//            }
//        }
//    }
//    
//    private func monthYearString(from date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MMMM yyyy"
//        return formatter.string(from: date)
//    }
//}
//
//struct WeekDayCell: View {
//    let date: Date
//    let isSelected: Bool
//    let isToday: Bool
//    
//    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
//    
//    private var dayName: String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "E"
//        return formatter.string(from: date)
//    }
//    
//    private var dayNumber: String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "d"
//        return formatter.string(from: date)
//    }
//    
//    var body: some View {
//        VStack(spacing: 8) {
//            Text(dayName)
//                .font(.caption)
//                .foregroundColor(.gray)
//            
//            Text(dayNumber)
//                .font(.title3.weight(.semibold))
//                .frame(width: 32, height: 32)
//                .background(
//                    Circle()
//                        .fill(isSelected ? primaryColor : Color.clear)
//                        .overlay(
//                            Circle()
//                                .stroke(isToday && !isSelected ? primaryColor : Color.clear, lineWidth: 1.5)
//                        )
//                )
//                .foregroundColor(isSelected ? .white : (isToday ? primaryColor : .primary))
//        }
//        .frame(width: 50, height: 60)
//    }
//}
//
//struct AppointmentView: View {
//    let appointment: Appointment
//    @State private var patientName: String = "Unknown"
//    @Binding var showPatientProfileView: Bool
//    @Binding var selectedPatientId: String?
//    @Binding var selectedApptId: String?
//
//    private let db = Firestore.firestore()
//    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
//    private let secondaryColor = Color(red: 0.55, green: 0.48, blue: 0.99)
//    private let cardBackground = Color.white
//    private let forNowColor = Color(red: 0.51, green: 0.44, blue: 0.87)
//
//    var body: some View {
//        Button(action: {
//            selectedPatientId = appointment.patientId
//            selectedApptId = appointment.apptId
//            showPatientProfileView = true
//        }) {
//            VStack(alignment: .leading, spacing: 8) {
//                HStack {
//                    Circle()
//                        .fill(statusColor)
//                        .frame(width: 12, height: 12)
//
//                    Text(patientName)
//                        .font(.system(.headline, design: .rounded, weight: .bold))
//                        .foregroundColor(.primary)
//
//                    Spacer()
//
//                    Text(appointment.date?.formatted(.dateTime.hour().minute()) ?? "N/A")
//                        .font(.system(.subheadline, design: .rounded))
//                        .foregroundColor(.secondary)
//                }
//
//                HStack {
//                    Text(appointment.status.capitalized)
//                        .font(.system(.caption, design: .rounded, weight: .medium))
//                        .padding(.vertical, 4)
//                        .padding(.horizontal, 8)
//                        .background(statusColor.opacity(0.2))
//                        .foregroundColor(statusColor)
//                        .overlay(
//                            Capsule()
//                                .stroke(forNowColor, lineWidth: 1)
//                        )
//                        .clipShape(Capsule())
//
//                    if appointment.followUpRequired ?? false {
//                        Image(systemName: "arrow.clockwise")
//                            .font(.system(size: 12))
//                            .foregroundColor(forNowColor)
//                    }
//                }
//
//                if !appointment.description.isEmpty {
//                    Text(appointment.description)
//                        .font(.system(.subheadline, design: .rounded))
//                        .foregroundColor(.secondary)
//                        .lineLimit(2)
//                }
//            }
//            .padding(16)
//            .background(cardBackground)
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
//            .scaleEffect(showPatientProfileView ? 0.98 : 1.0)
//            .animation(.easeInOut(duration: 0.2), value: showPatientProfileView)
//        }
//        .onAppear {
//            fetchPatientName()
//        }
//    }
//
//    private var statusColor: Color {
//        switch appointment.status.lowercased() {
//        case "cancelled":
//            return .red
//        case "scheduled":
//            return .orange
//        case "completed":
//            return .green
//        default:
//            return .gray
//        }
//    }
//
//    private func fetchPatientName() {
//        db.collection("patients")
//            .whereField("patientId", isEqualTo: appointment.patientId)
//            .getDocuments { snapshot, error in
//                if let error = error {
//                    print("Error fetching patient: \(error)")
//                    return
//                }
//
//                guard let documents = snapshot?.documents, !documents.isEmpty else {
//                    print("No patient found for patientId: \(appointment.patientId)")
//                    patientName = "Unknown"
//                    return
//                }
//
//                if let data = documents.first?.data(),
//                   let userData = data["userData"] as? [String: Any],
//                   let name = userData["Name"] as? String {
//                    patientName = name
//                    print("Patient name fetched: \(name) for patientId: \(appointment.patientId)")
//                } else {
//                    print("Failed to fetch patient name for patientId: \(appointment.patientId)")
//                    patientName = "Unknown"
//                }
//            }
//    }
//}
//
//struct MonthView: View {
//    @Binding var selectedDate: Date
//    @Binding var viewMode: CalendarViewMode
//    
//    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
//    private let cardBackground = Color.white
//    
//    var body: some View {
//        HStack {
//            Spacer()
//            VStack(spacing: 8) {
//                MonthHeaderView(selectedDate: $selectedDate)
//                CalendarGridView(selectedDate: $selectedDate, viewMode: $viewMode)
//            }
//            .padding(12)
//            .background(cardBackground)
//            .clipShape(RoundedRectangle(cornerRadius: 16))
//            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
//            .frame(width: 320)
//            Spacer()
//        }
//        .padding(.horizontal, 12)
//    }
//}
//
//struct MonthHeaderView: View {
//    @Binding var selectedDate: Date
//    
//    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
//    
//    var body: some View {
//        HStack {
//            Button(action: { changeMonth(by: -1) }) {
//                Image(systemName: "chevron.left")
//                    .foregroundColor(primaryColor)
//                    .padding(8)
//            }
//            
//            Spacer()
//            
//            Text(selectedDate.formatted(.dateTime.month(.wide).year()))
//                .font(.title2.weight(.bold))
//                .foregroundColor(.primary)
//            
//            Spacer()
//            
//            Button(action: { changeMonth(by: 1) }) {
//                Image(systemName: "chevron.right")
//                    .foregroundColor(primaryColor)
//                    .padding(8)
//            }
//        }
//        .padding(.horizontal, 8)
//    }
//    
//    private func changeMonth(by value: Int) {
//        selectedDate = Calendar.current.date(byAdding: .month, value: value, to: selectedDate)!
//    }
//}
//
//struct CalendarGridView: View {
//    @Binding var selectedDate: Date
//    @Binding var viewMode: CalendarViewMode
//    
//    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
//    let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
//    
//    var daysInMonth: [Date] {
//        let calendar = Calendar.current
//        let range = calendar.range(of: .day, in: .month, for: selectedDate)!
//        let components = calendar.dateComponents([.year, .month], from: selectedDate)
//        
//        return range.compactMap { day -> Date? in
//            var newComponents = components
//            newComponents.day = day
//            return calendar.date(from: newComponents)
//        }
//    }
//    
//    var firstWeekday: Int {
//        let calendar = Calendar.current
//        let components = calendar.dateComponents([.year, .month], from: selectedDate)
//        let firstDay = calendar.date(from: components)!
//        return calendar.component(.weekday, from: firstDay)
//    }
//    
//    var body: some View {
//        VStack(spacing: 4) {
//            LazyVGrid(columns: columns, spacing: 4) {
//                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { weekday in
//                    Text(weekday)
//                        .font(.system(.caption, design: .rounded, weight: .medium))
//                        .foregroundColor(.secondary)
//                        .frame(maxWidth: .infinity)
//                }
//            }
//            
//            LazyVGrid(columns: columns, spacing: 4) {
//                ForEach(0..<firstWeekday-1, id: \.self) { _ in
//                    Color.clear
//                }
//                
//                ForEach(daysInMonth, id: \.self) { date in
//                    DayCell(date: date, selectedDate: $selectedDate, viewMode: $viewMode)
//                }
//            }
//        }
//        .padding(.horizontal, 8)
//        .padding(.bottom, 8)
//    }
//}
//
//struct DayCell: View {
//    let date: Date
//    @Binding var selectedDate: Date
//    @Binding var viewMode: CalendarViewMode
//    
//    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
//    
//    var body: some View {
//        Button(action: {
//            selectedDate = date
//            viewMode = .day
//        }) {
//            Text(date.formatted(.dateTime.day()))
//                .font(.system(.subheadline, design: .rounded, weight: .medium))
//                .foregroundColor(date.isSameDay(as: Date()) ? primaryColor : .primary)
//                .frame(width: 32, height: 32)
//                .background(date.isSameDay(as: selectedDate) ? primaryColor : Color.clear)
//                .foregroundColor(date.isSameDay(as: selectedDate) ? .white : .primary)
//                .clipShape(Circle())
//        }
//    }
//}
//
//enum CalendarViewMode {
//    case month, day
//}
//
//extension Date {
//    func isSameDay(as other: Date) -> Bool {
//        Calendar.current.isDate(self, inSameDayAs: other)
//    }
//}
//
//extension Color {
//    static let customButton = Color(red: 0.43, green: 0.34, blue: 0.99)
//    static let customCard = Color.white
//}
//
//struct DoctorDashboardView_Previews: PreviewProvider {
//    static var previews: some View {
//        DoctorDashboardView()
//    }
//}

import SwiftUI
import FirebaseFirestore
import FirebaseAuth



struct DoctorDashboardView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var selectedDate = Date()
    @State private var viewMode: CalendarViewMode = .day
    @State private var appointments: [Appointment] = []
    @State private var doctorName: String = "Doctor"
    @State private var doctorId: String = ""
    @State private var showPatientProfileView = false
    @State private var selectedPatientId: String? = nil
    @State private var selectedApptId: String? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    private let secondaryColor = Color(red: 0.55, green: 0.48, blue: 0.99)
    private let backgroundColor = Color(red: 0.97, green: 0.97, blue: 1.0)
    private let cardBackground = Color.white
    private let forNowColor = Color(red: 0.51, green: 0.44, blue: 0.87)
    
    private let db = Firestore.firestore()
    
    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Welcome, \(doctorName)")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Today's Overview")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Main Content
                switch viewMode {
                case .month:
                    MonthView(selectedDate: $selectedDate, viewMode: $viewMode)
                case .day:
                    DayView(
                        selectedDate: $selectedDate,
                        appointments: appointments.filter { $0.date?.isSameDay(as: selectedDate) ?? false },
                        showPatientProfileView: $showPatientProfileView,
                        selectedPatientId: $selectedPatientId,
                        selectedApptId: $selectedApptId
                    )
                }
            }
        }
        .onAppear {
            updateDoctorData()
        }
        .onReceive(authManager.$currentStaffMember) { _ in
            updateDoctorData()
        }
        .navigationDestination(isPresented: $showPatientProfileView) {
            if let patientId = selectedPatientId, let apptId = selectedApptId {
                PatientProfileView(
                    patientIdentifier: patientId,
                    doctorId: doctorId,
                    doctorName: doctorName,
                    apptId: apptId
                )
            }
        }
    }
    
    private func updateDoctorData() {
        if let staff = authManager.currentDoctor {
            doctorName = staff.doctor_name
            doctorId = staff.id ?? ""
            guard let uid = Auth.auth().currentUser?.uid else {
                doctorId = ""
                doctorName = "Doctor"
                appointments = []
                return
            }
            
            db.collection("doctors").document(uid).getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching doctor: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data(), snapshot?.exists == true,
                      let docId = data["Doctorid"] as? String,
                      let name = data["Doctor_name"] as? String else {
                    doctorId = ""
                    doctorName = "Doctor"
                    appointments = []
                    return
                }
                
                doctorId = docId
                doctorName = name
                fetchData()
            }
        } else {
            doctorName = "Doctor"
            doctorId = ""
            appointments = []
        }
    }
    
    private func fetchData() {
        guard !doctorId.isEmpty else {
            appointments = []
            return
        }
        
        db.collection("appointments")
            .whereField("docId", isEqualTo: doctorId)
            .getDocuments(source: .default) { snapshot, error in
                if let error = error {
                    print("Error fetching appointments: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No appointment documents found for docId: \(doctorId)")
                    appointments = []
                    return
                }
                
                appointments = documents.compactMap { doc -> Appointment? in
                    let data = doc.data()
                    print("Appointment document data: \(data)")
                    
                    guard let apptId = data["apptId"] as? String,
                          let patientId = data["patientId"] as? String,
                          let docId = data["docId"] as? String,
                          let description = (data["description"] as? String) ?? (data["Description"] as? String),
                          let status = (data["status"] as? String) ?? (data["Status"] as? String) else {
                        print("Failed to map document: \(doc.documentID), missing required fields")
                        return nil
                    }
                    
                    let appointment = Appointment(
                        id: doc.documentID,
                        apptId: apptId,
                        patientId: patientId,
                        description: description,
                        docId: docId,
                        status: status.lowercased(),
                        billingStatus: data["billingStatus"] as? String ?? "",
                        amount: data["amount"] as? Double,
                        date: (data["date"] as? Timestamp)?.dateValue(),
                        doctorsNotes: (data["doctorsNotes"] as? String) ?? (data["doctorNotes"] as? String),
                        prescriptionId: data["prescriptionId"] as? String,
                        followUpRequired: data["followUpRequired"] as? Bool,
                        followUpDate: (data["followUpDate"] as? Timestamp)?.dateValue()
                    )
                    print("Mapped appointment: \(appointment)")
                    return appointment
                }
                .sorted { (appt1, appt2) -> Bool in
                    guard let date1 = appt1.date, let date2 = appt2.date else {
                        return false
                    }
                    return date1 < date2
                }
                
                print("Total appointments fetched: \(appointments.count)")
            }
    }
}

struct DayView: View {
    @Binding var selectedDate: Date
    let appointments: [Appointment]
    @Binding var showPatientProfileView: Bool
    @Binding var selectedPatientId: String?
    @Binding var selectedApptId: String?

    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    private let cardBackground = Color.white
    private let backgroundColor = Color(red: 0.97, green: 0.97, blue: 1.0)

    var scheduleTitle: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        if calendar.isDate(selectedDate, inSameDayAs: today) {
            return "Today's Schedule"
        } else if calendar.isDate(selectedDate, inSameDayAs: tomorrow) {
            return "Tomorrow's Schedule"
        } else {
            return "Upcoming Schedule"
        }
    }

    // Sort appointments to move "completed" to the bottom
    private var sortedAppointments: [Appointment] {
        appointments.sorted { appt1, appt2 in
            if appt1.status.lowercased() == "completed" && appt2.status.lowercased() != "completed" {
                return false // appt1 (completed) goes after appt2
            } else if appt1.status.lowercased() != "completed" && appt2.status.lowercased() == "completed" {
                return true // appt1 (non-completed) goes before appt2
            } else {
                // If both are completed or both are non-completed, maintain date order
                guard let date1 = appt1.date, let date2 = appt2.date else {
                    return false
                }
                return date1 < date2
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Calendar Week View
            WeekScrollerView(selectedDate: $selectedDate)

            ScrollView {
                VStack(spacing: 12) {
                    Text(scheduleTitle)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                    if sortedAppointments.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("No appointments scheduled")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                        .background(backgroundColor)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    } else {
                        ForEach(sortedAppointments, id: \.id) { appointment in
                            AppointmentView(
                                appointment: appointment,
                                showPatientProfileView: $showPatientProfileView,
                                selectedPatientId: $selectedPatientId,
                                selectedApptId: $selectedApptId
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
}

struct WeekScrollerView: View {
    @Binding var selectedDate: Date
    @State private var showDatePicker = false
    private let calendar = Calendar.current
    
    private var weekStartDate: Date {
        let today = calendar.startOfDay(for: Date())
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)) ?? today
    }
    
    private var weekDates: [Date] {
        (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: weekStartDate)
        }
    }
    
    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    private let cardBackground = Color.white
    
    var body: some View {
        HStack {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackground)
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
                
                VStack(spacing: 8) {
                    HStack {
                        Button(action: { moveWeek(by: -1) }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(primaryColor)
                                .padding(8)
                        }
                        
                        Spacer()
                        
                        Text(monthYearString(from: selectedDate))
                            .font(.title3)
                            .fontWeight(.bold)
                            .onTapGesture {
                                showDatePicker = true
                            }
                        
                        Spacer()
                        
                        Button(action: { moveWeek(by: 1) }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(primaryColor)
                                .padding(8)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 12)
                    
                    HStack(spacing: 1) {
                        ForEach(weekDates, id: \.self) { date in
                            WeekDayCell(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isToday: calendar.isDateInToday(date)
                            )
                            .onTapGesture {
                                withAnimation {
                                    selectedDate = date
                                }
                            }
                        }
                    }
                    .padding(.bottom, 10)
                }
            }
            .frame(width: UIScreen.main.bounds.width - 32, height: 120)
            Spacer()
        }
        .sheet(isPresented: $showDatePicker) {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .presentationDetents([.medium])
            .padding()
        }
    }
    
    private func moveWeek(by weeks: Int) {
        if let newDate = calendar.date(byAdding: .weekOfYear, value: weeks, to: weekStartDate) {
            withAnimation {
                selectedDate = newDate
            }
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

struct WeekDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    
    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(dayName)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(dayNumber)
                .font(.title3.weight(.semibold))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? primaryColor : Color.clear)
                        .overlay(
                            Circle()
                                .stroke(isToday && !isSelected ? primaryColor : Color.clear, lineWidth: 1.5)
                        )
                )
                .foregroundColor(isSelected ? .white : (isToday ? primaryColor : .primary))
        }
        .frame(width: 50, height: 60)
    }
}

struct AppointmentView: View {
    let appointment: Appointment
    @State private var patientName: String = "Unknown"
    @Binding var showPatientProfileView: Bool
    @Binding var selectedPatientId: String?
    @Binding var selectedApptId: String?

    private let db = Firestore.firestore()
    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    private let secondaryColor = Color(red: 0.55, green: 0.48, blue: 0.99)
    private let cardBackground = Color.white
    private let forNowColor = Color(red: 0.51, green: 0.44, blue: 0.87)

    var body: some View {
        Button(action: {
            selectedPatientId = appointment.patientId
            selectedApptId = appointment.apptId
            showPatientProfileView = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)

                    Text(patientName)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Text(appointment.date?.formatted(.dateTime.hour().minute()) ?? "N/A")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text(appointment.status.capitalized)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .overlay(
                            Capsule()
                                .stroke(forNowColor, lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }

                if !appointment.description.isEmpty {
                    Text(appointment.description)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(16)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            .scaleEffect(showPatientProfileView ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: showPatientProfileView)
        }
        .onAppear {
            fetchPatientName()
        }
    }

    private var statusColor: Color {
        switch appointment.status.lowercased() {
        case "cancelled":
            return .red
        case "scheduled":
            return .orange
        case "completed":
            return .green
        default:
            return .gray
        }
    }

    private func fetchPatientName() {
        db.collection("patients")
            .whereField("patientId", isEqualTo: appointment.patientId)
            .getDocuments(source: .default) { snapshot, error in
                if let error = error {
                    print("Error fetching patient: \(error)")
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No patient found for patientId: \(appointment.patientId)")
                    patientName = "Unknown"
                    return
                }

                if let data = documents.first?.data(),
                   let userData = data["userData"] as? [String: Any],
                   let name = userData["Name"] as? String {
                    patientName = name
                    print("Patient name fetched: \(name) for patientId: \(appointment.patientId)")
                } else {
                    print("Failed to fetch patient name for patientId: \(appointment.patientId)")
                    patientName = "Unknown"
                }
            }
    }
}

struct MonthView: View {
    @Binding var selectedDate: Date
    @Binding var viewMode: CalendarViewMode
    
    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    private let cardBackground = Color.white
    
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                MonthHeaderView(selectedDate: $selectedDate)
                CalendarGridView(selectedDate: $selectedDate, viewMode: $viewMode)
            }
            .padding(12)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
            .frame(width: 320)
            Spacer()
        }
        .padding(.horizontal, 12)
    }
}

struct MonthHeaderView: View {
    @Binding var selectedDate: Date
    
    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    
    var body: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(primaryColor)
                    .padding(8)
            }
            
            Spacer()
            
            Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(primaryColor)
                    .padding(8)
            }
        }
        .padding(.horizontal, 8)
    }
    
    private func changeMonth(by value: Int) {
        selectedDate = Calendar.current.date(byAdding: .month, value: value, to: selectedDate)!
    }
}

struct CalendarGridView: View {
    @Binding var selectedDate: Date
    @Binding var viewMode: CalendarViewMode
    
    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    var daysInMonth: [Date] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: selectedDate)!
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        
        return range.compactMap { day -> Date? in
            var newComponents = components
            newComponents.day = day
            return calendar.date(from: newComponents)
        }
    }
    
    var firstWeekday: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        let firstDay = calendar.date(from: components)!
        return calendar.component(.weekday, from: firstDay)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<firstWeekday-1, id: \.self) { _ in
                    Color.clear
                }
                
                ForEach(daysInMonth, id: \.self) { date in
                    DayCell(date: date, selectedDate: $selectedDate, viewMode: $viewMode)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
}

struct DayCell: View {
    let date: Date
    @Binding var selectedDate: Date
    @Binding var viewMode: CalendarViewMode
    
    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    
    var body: some View {
        Button(action: {
            selectedDate = date
            viewMode = .day
        }) {
            Text(date.formatted(.dateTime.day()))
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundColor(date.isSameDay(as: Date()) ? primaryColor : .primary)
                .frame(width: 32, height: 32)
                .background(date.isSameDay(as: selectedDate) ? primaryColor : Color.clear)
                .foregroundColor(date.isSameDay(as: selectedDate) ? .white : .primary)
                .clipShape(Circle())
        }
    }
}

enum CalendarViewMode {
    case month, day
}

extension Date {
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

extension Color {
    static let customButton = Color(red: 0.43, green: 0.34, blue: 0.99)
    static let customCard = Color.white
}

struct DoctorDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DoctorDashboardView()
    }
}
