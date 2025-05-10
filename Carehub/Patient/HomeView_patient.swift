import SwiftUI
import FirebaseFirestore
import AVFoundation

struct Notification: Identifiable {
    let id: String
    let title: String
    let message: String
    let date: Date
    let appointmentId: String?
    let type: String
}

struct HomeView_patient: View {
    let patient: PatientF
    @Environment(\.colorScheme) var colorScheme
    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    private let secondaryColor = Color(red: 0.55, green: 0.48, blue: 0.99)
    private let backgroundColor = Color(red: 0.97, green: 0.97, blue: 1.0)
    private let cardBackground = Color.white
    @State private var upcomingSchedules: [Appointment] = []
    @State private var isLoading = true
    @State private var navigateToBooking = false
    @State private var navigateToNotifications = false
    @State private var listener: ListenerRegistration?
    @State private var notificationCount: Int = 0
    @State private var hasViewedNotifications: Bool = UserDefaults.standard.bool(forKey: "hasViewedNotifications") ?? false
    @State private var lastNotificationViewTime: Date? = UserDefaults.standard.object(forKey: "lastNotificationViewTime") as? Date
    @StateObject private var viewModel = AppointmentViewModel()
    private let forNowColor = Color(red: 0.51, green: 0.44, blue: 0.87)
    @AppStorage("isVoiceOverEnabled") private var isVoiceOverEnabled = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var isInitialLoad = true
    @State private var navigateToChat = false
    
    var body: some View {
        NavigationStack {
            mainContent
        }
    }

    private var mainContent: some View {
        ZStack {
            backgroundColor
                .edgesIgnoringSafeArea(.all)
            
            scrollContent
            // Chatbot Icon Button (Floating Action Button)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        navigateToChat = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(primaryColor)
                                .frame(width: 60, height: 60)
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: "message.fill")
                                .foregroundColor(.white)
                                .font(.system(size: FontSizeManager.fontSize(for: 24)))
                        }
                    }
                    .accessibilityLabel("Open Chatbot")
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToChat) {
            ChatView()
        }
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: handleOnAppear)
        .onDisappear(perform: handleOnDisappear)
//        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AppointmentBooked")), perform: handleAppointmentBooked)
//        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AppointmentCancelled")), perform: handleAppointmentCancelled)
        .navigationDestination(isPresented: $navigateToBooking) {
            DoctorView(patientId: patient.patientId)
        }
        .navigationDestination(isPresented: $navigateToNotifications) {
            NotificationsView(
                upcomingSchedules: upcomingSchedules,
                getDoctorName: getDoctorName,
                getDoctorSpecialty: getDoctorSpecialty,
                formatDate: formatDate
            )
        }
        .onChange(of: isVoiceOverEnabled) { newValue in
            if newValue {
                readHomeViewText()
            } else {
                speechSynthesizer.stopSpeaking(at: .immediate)
            }
        }
    }

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                headerSection
                bookAppointmentCard
                upcomingAppointmentsSection
                recentPrescriptionsSection
                medicalTestsSection
                visitedDoctorsSection
            }
            .padding(.bottom, 24)
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Hello, \(patient.userData.Name)")
                    .font(FontSizeManager.font(for: 28, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Welcome to CareHub")
                    .font(FontSizeManager.font(for: 16, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            notificationButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var notificationButton: some View {
        Button(action: handleNotificationButton) {
            ZStack {
                Circle()
                    .fill(cardBackground)
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                Image(systemName: "bell.fill")
                    .foregroundColor(primaryColor)
                    .font(.system(size: FontSizeManager.fontSize(for: 18)))
                
                if notificationCount > 0 {
                    notificationBadge
                }
            }
        }
        .accessibilityLabel("Notifications, \(notificationCount) new")
    }

    private var notificationBadge: some View {
        ZStack {
            Circle()
                .fill(Color.red)
                .frame(width: 20, height: 20)
            Text("\(notificationCount)")
                .font(FontSizeManager.font(for: 12, weight: .bold))
                .foregroundColor(.white)
        }
        .offset(x: 12, y: -12)
    }

    // MARK: - Book Appointment Card
    private var bookAppointmentCard: some View {
        Button(action: { navigateToBooking = true }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [forNowColor, secondaryColor]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .shadow(color: primaryColor.opacity(0.2), radius: 10, x: 0, y: 5)
                
                HStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                        .padding(.leading, 16)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Book an Appointment")
                            .font(FontSizeManager.font(for: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Schedule with your preferred doctor")
                            .font(FontSizeManager.font(for: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                        .font(.system(size: FontSizeManager.fontSize(for: 18)))
                        .padding(.trailing, 16)
                }
                .padding(.vertical, 16)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    // MARK: - Upcoming Appointments Section
    private var upcomingAppointmentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Upcoming Appointments",
                hasContent: !upcomingSchedules.isEmpty
            ) {
                NavigationLink {
                    AllAppointmentsView(
                        upcomingSchedules: $upcomingSchedules,
                        getDoctorName: getDoctorName,
                        getDoctorSpecialty: getDoctorSpecialty,
                        formatDate: formatDate
                    )
                } label: {
                    Text("See All")
                        .font(FontSizeManager.font(for: 14, weight: .semibold))
                        .foregroundColor(primaryColor)
                }
            }
            
            if isLoading {
                loadingView
            } else if upcomingSchedules.isEmpty {
                emptyStateView(
                    icon: "calendar",
                    title: "No Upcoming Appointments",
                    message: "You don't have any scheduled appointments"
                )
            } else {
                appointmentCards
            }
        }
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
            Spacer()
        }
    }

    private var appointmentCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach($upcomingSchedules) { $appointment in
                    ImprovedAppointmentCard(
                        doctorName: getDoctorName(for: appointment.docId),
                        specialty: getDoctorSpecialty(for: appointment.docId),
                        date: formatDateTime(appointment.date ?? Date()).date,
                        time: formatDateTime(appointment.date ?? Date()).time,
                        imageName: "doctor1",
                        appointment: $appointment
                    )
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Recent Prescriptions Section
    private var recentPrescriptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Recent Prescriptions",
                hasContent: !viewModel.recentPrescriptions.isEmpty
            ) {
                NavigationLink {
                    AllPrescriptionsView(
                        prescriptions: viewModel.recentPrescriptions,
                        formatDate: formatDate,
                        viewModel: viewModel
                    )
                } label: {
                    Text("See All")
                        .font(FontSizeManager.font(for: 14, weight: .semibold))
                        .foregroundColor(primaryColor)
                }
            }
            
            if viewModel.recentPrescriptions.isEmpty {
                emptyStateView(
                    icon: "doc.text",
                    title: "No Recent Prescriptions",
                    message: "Your prescriptions will appear here"
                )
            } else {
                prescriptionCards
            }
        }
        .onAppear {
            print("Fetching recent prescriptions for patientId: \(patient.patientId)")
            viewModel.fetchRecentPrescriptions(forPatientId: patient.patientId)
            print("Recent prescriptions count: \(viewModel.recentPrescriptions.count)")
        }
    }

    private var prescriptionCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.recentPrescriptions) { appointment in
                    NavigationLink {
                        prescriptionDestination(for: appointment)
                    } label: {
                        ImprovedMedicalRecordCard(
                            type: appointment.status,
                            doctorName: getDoctorName(for: appointment.docId),
                            date: formatDate(appointment.date),
                            title: appointment.description
                        )
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Medical Tests Section
    private var medicalTestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Recent Medical Reports",
                hasContent: !viewModel.medicalTests.isEmpty
            ) {
                NavigationLink {
                    AllTestsView(
                        prescriptions: viewModel.medicalTests,
                        formatDate: formatDate,
                        viewModel: viewModel
                    )
                } label: {
                    Text("See All")
                        .font(FontSizeManager.font(for: 14, weight: .semibold))
                        .foregroundColor(primaryColor)
                }
            }
            
            if viewModel.medicalTests.isEmpty {
                emptyStateView(
                    icon: "doc.text",
                    title: "No Recent Reports",
                    message: "Your reports will appear here"
                )
            } else {
                medicalTestCards
            }
        }
        .onAppear {
            Task {
                print("Fetching recent reports for patientId: \(patient.patientId)")
                await viewModel.fetchMedicalTests(forPatientId: patient.patientId)
                print("Recent reports count: \(viewModel.medicalTests.count)")
            }
        }
    }

    private var medicalTestCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.medicalTests) { appointment in
                    NavigationLink {
                        medicalTestDestination(for: appointment)
                    } label: {
                        ImprovedMedicalRecordCard(
                            type: appointment.status,
                            doctorName: appointment.doc,
                            date: appointment.date,
                            title: appointment.testName
                        )
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Visited Doctors Section
    private var visitedDoctorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Previously Visited Doctors",
                hasContent: !viewModel.recentPrescriptions.isEmpty
            ) {
                NavigationLink {
                    AllVisitedDoctorsView(
                        recentPrescriptions: viewModel.recentPrescriptions,
                        formatDate: formatDate
                    )
                } label: {
                    Text("See All")
                        .font(FontSizeManager.font(for: 14, weight: .semibold))
                        .foregroundColor(primaryColor)
                }
            }
            
            if viewModel.recentPrescriptions.isEmpty {
                emptyStateView(
                    icon: "person.2",
                    title: "No Doctor Visits",
                    message: "Your previously visited doctors will appear here"
                )
            } else {
                visitedDoctorsCards
            }
        }
    }

    private var visitedDoctorsCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.recentPrescriptions) { appointment in
                    ImprovedDoctorCard(
                        name: getDoctorName(for: appointment.docId),
                        specialty: "General Medicine",
                        lastVisit: formatDate(appointment.date),
                        imageName: "defaultDoctorImage"
                    )
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Helper Functions
    private func handleOnAppear() {
        if listener == nil {
            isLoading = true
            loadDoctorData {
                setupSnapshotListener()
            }
        }
        if isInitialLoad {
            isInitialLoad = false
        } else if isVoiceOverEnabled {
            readHomeViewText()
        }
        print("Recent prescriptions count on appear: \(viewModel.recentPrescriptions.count)")
    }

    private func handleOnDisappear() {
        listener?.remove()
        listener = nil
        speechSynthesizer.stopSpeaking(at: .immediate)
    }

    private func handleAppointmentBooked(_ notification: Notification) {
        listener?.remove()
        listener = nil
        isLoading = true
        setupSnapshotListener()
    }

    private func handleAppointmentCancelled(_ notification: Notification) {
        listener?.remove()
        listener = nil
        isLoading = true
        setupSnapshotListener()
    }

    private func handleNotificationButton() {
        navigateToNotifications = true
        hasViewedNotifications = true
        lastNotificationViewTime = Date()
        UserDefaults.standard.set(true, forKey: "hasViewedNotifications")
        UserDefaults.standard.set(lastNotificationViewTime, forKey: "lastNotificationViewTime")
    }

//    var body: some View {
//        NavigationStack {
//            ZStack {
//                backgroundColor
//                    .edgesIgnoringSafeArea(.all)
//
//                ScrollView(showsIndicators: false) {
//                    VStack(spacing: 24) {
//                        // Header
//                        HStack(alignment: .center) {
//                            VStack(alignment: .leading, spacing: 6) {
//                                Text("Hello, \(patient.userData.Name)")
//                                    .font(FontSizeManager.font(for: 28, weight: .bold))
//                                    .foregroundColor(.black)
//
//                                Text("Welcome to CareHub")
//                                    .font(FontSizeManager.font(for: 16, weight: .medium))
//                                    .foregroundColor(.gray)
//                            }
//
//                            Spacer()
//
//                            Button(action: {
//                                navigateToNotifications = true
//                                hasViewedNotifications = true
//                                lastNotificationViewTime = Date()
//                                UserDefaults.standard.set(true, forKey: "hasViewedNotifications")
//                                UserDefaults.standard.set(lastNotificationViewTime, forKey: "lastNotificationViewTime")
//                            }) {
//                                ZStack {
//                                    Circle()
//                                        .fill(cardBackground)
//                                        .frame(width: 44, height: 44)
//                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
//
//                                    Image(systemName: "bell.fill")
//                                        .foregroundColor(primaryColor)
//                                        .font(.system(size: FontSizeManager.fontSize(for: 18)))
//
//                                    if notificationCount > 0 {
//                                        ZStack {
//                                            Circle()
//                                                .fill(Color.red)
//                                                .frame(width: 20, height: 20)
//                                            Text("\(notificationCount)")
//                                                .font(FontSizeManager.font(for: 12, weight: .bold))
//                                                .foregroundColor(.white)
//                                        }
//                                        .offset(x: 12, y: -12)
//                                    }
//                                }
//                            }
//                            .accessibilityLabel("Notifications, \(notificationCount) new")
//                        }
//                        .padding(.horizontal, 16)
//                        .padding(.top, 16)
//
//                        // Book Appointment Card
//                        Button(action: {
//                            navigateToBooking = true
//                        }) {
//                            ZStack {
//                                RoundedRectangle(cornerRadius: 16)
//                                    .fill(LinearGradient(
//                                        gradient: Gradient(colors: [forNowColor, secondaryColor]),
//                                        startPoint: .topLeading,
//                                        endPoint: .bottomTrailing
//                                    ))
//                                    .shadow(color: primaryColor.opacity(0.2), radius: 10, x: 0, y: 5)
//
//                                HStack(spacing: 16) {
//                                    Image(systemName: "calendar.badge.plus")
//                                        .resizable()
//                                        .scaledToFit()
//                                        .frame(width: 50, height: 50)
//                                        .foregroundColor(.white)
//                                        .padding(.leading, 16)
//
//                                    VStack(alignment: .leading, spacing: 8) {
//                                        Text("Book an Appointment")
//                                            .font(FontSizeManager.font(for: 18, weight: .bold))
//                                            .foregroundColor(.white)
//
//                                        Text("Schedule with your preferred doctor")
//                                            .font(FontSizeManager.font(for: 14, weight: .medium))
//                                            .foregroundColor(.white.opacity(0.8))
//                                    }
//
//                                    Spacer()
//
//                                    Image(systemName: "chevron.right")
//                                        .foregroundColor(.white)
//                                        .font(.system(size: FontSizeManager.fontSize(for: 18)))
//                                        .padding(.trailing, 16)
//                                }
//                                .padding(.vertical, 16)
//                            }
//                            .frame(maxWidth: .infinity)
//                        }
//                        .buttonStyle(PlainButtonStyle())
//                        .padding(.horizontal, 16)
//                        .padding(.bottom, 10)
//
//                        // Upcoming Appointments Section
//                        VStack(alignment: .leading, spacing: 16) {
//                            sectionHeader(
//                                title: "Upcoming Appointments",
//                                hasContent: !upcomingSchedules.isEmpty
//                            ) {
//                                NavigationLink {
//                                    AllAppointmentsView(
//                                        upcomingSchedules: $upcomingSchedules,
//                                        getDoctorName: getDoctorName,
//                                        getDoctorSpecialty: getDoctorSpecialty,
//                                        formatDate: formatDate
//                                    )
//                                } label: {
//                                    Text("See All")
//                                        .font(FontSizeManager.font(for: 14, weight: .semibold))
//                                        .foregroundColor(primaryColor)
//                                }
//                            }
//
//                            if isLoading {
//                                HStack {
//                                    Spacer()
//                                    ProgressView()
//                                        .padding()
//                                    Spacer()
//                                }
//                            } else if upcomingSchedules.isEmpty {
//                                emptyStateView(
//                                    icon: "calendar",
//                                    title: "No Upcoming Appointments",
//                                    message: "You don't have any scheduled appointments"
//                                )
//                            } else {
//                                ScrollView(.horizontal, showsIndicators: false) {
//                                    HStack(spacing: 16) {
//                                        ForEach($upcomingSchedules) { $appointment in
//                                            ImprovedAppointmentCard(
//                                                doctorName: getDoctorName(for: appointment.docId),
//                                                specialty: getDoctorSpecialty(for: appointment.docId),
//                                                date: formatDateTime(appointment.date ?? Date()).date,
//                                                time: formatDateTime(appointment.date ?? Date()).time,
//                                                imageName: "doctor1",
//                                                appointment: $appointment
//                                            )
//                                        }
//                                    }
//                                    .padding(.vertical, 8)
//                                    .padding(.horizontal, 2)
//                                }
//                            }
//                        }
//
//                        // Recent Prescriptions Section
//                        VStack(alignment: .leading, spacing: 16) {
//                            sectionHeader(
//                                title: "Recent Prescriptions",
//                                hasContent: !viewModel.recentPrescriptions.isEmpty
//                            ) {
//                                NavigationLink {
//                                     AllPrescriptionsView(
//                                         prescriptions: viewModel.recentPrescriptions,
//                                         formatDate: formatDate,
//                                         viewModel: viewModel
//                                     )
//                                } label: {
//                                    Text("See All")
//                                        .font(FontSizeManager.font(for: 14, weight: .semibold))
//                                        .foregroundColor(primaryColor)
//                                }
//                            }
//
//                            if viewModel.recentPrescriptions.isEmpty {
//                                emptyStateView(
//                                    icon: "doc.text",
//                                    title: "No Recent Prescriptions",
//                                    message: "Your prescriptions will appear here"
//                                )
//                            } else {
//                                ScrollView(.horizontal, showsIndicators: false) {
//                                    HStack(spacing: 16) {
//                                        ForEach(viewModel.recentPrescriptions) { appointment in
//                                            NavigationLink {
//                                                prescriptionDestination(for: appointment)
//                                            } label: {
//                                                ImprovedMedicalRecordCard(
//                                                    type: appointment.status,
//                                                    doctorName: getDoctorName(for: appointment.docId),
//                                                    date: formatDate(appointment.date),
//                                                    title: appointment.description
//                                                )
//                                            }
//                                        }
//                                    }
//                                    .padding(.vertical, 8)
//                                    .padding(.horizontal, 2)
//                                }
//                            }
//                        }
//                        .onAppear {
//                            print("Fetching recent prescriptions for patientId: \(patient.patientId)")
//                            viewModel.fetchRecentPrescriptions(forPatientId: patient.patientId)
//                            print("Recent prescriptions count: \(viewModel.recentPrescriptions.count)")
//                        }
//
//                        //medical tests section
//
//                        VStack(alignment: .leading, spacing: 16) {
//                            sectionHeader(
//                                title: "Recent Medical Reports",
//                                hasContent: !viewModel.medicalTests.isEmpty
//                            ) {
//                                NavigationLink {
//                                     AllTestsView(
//                                         prescriptions: viewModel.medicalTests,
//                                         formatDate: formatDate,
//                                         viewModel: viewModel
//                                     )
//                                } label: {
//                                    Text("See All")
//                                        .font(FontSizeManager.font(for: 14, weight: .semibold))
//                                        .foregroundColor(primaryColor)
//                                }
//                            }
//
//                            if viewModel.medicalTests.isEmpty {
//                                emptyStateView(
//                                    icon: "doc.text",
//                                    title: "No Recent Reports",
//                                    message: "Your reports will appear here"
//                                )
//                            } else {
//                                ScrollView(.horizontal, showsIndicators: false) {
//                                    HStack(spacing: 16) {
//                                        ForEach(viewModel.medicalTests) { appointment in
//                                            NavigationLink {
//                                                prescriptionDestination(for: appointment)
//                                            } label: {
//                                                ImprovedMedicalRecordCard(
//                                                    type: appointment.status,
//                                                    doctorName: appointment.doc,
//                                                    date: formatDate(appointment.date),
//                                                    title: appointment.testName
//                                                )
//                                            }
//                                        }
//                                    }
//                                    .padding(.vertical, 8)
//                                    .padding(.horizontal, 2)
//                                }
//                            }
//                        }
//                        .onAppear {
//                            Task {
//                                print("Fetching recent reports for patientId: \(patient.patientId)")
//                                await viewModel.fetchMedicalTests(forPatientId: patient.patientId)
//                                print("Recent reports count: \(viewModel.medicalTests.count)")
//                                await viewModel.fetchRecentPrescriptions(forPatientId: patient.patientId)
//                            }
//                        }
//
//                        // Previously Visited Doctors Section
//                        VStack(alignment: .leading, spacing: 16) {
//                            sectionHeader(
//                                title: "Previously Visited Doctors",
//                                hasContent: !viewModel.recentPrescriptions.isEmpty
//                            ) {
//                                NavigationLink {
//                                    AllVisitedDoctorsView(
//                                        recentPrescriptions: viewModel.recentPrescriptions,
//                                        formatDate: formatDate
//                                    )
//                                } label: {
//                                    Text("See All")
//                                        .font(FontSizeManager.font(for: 14, weight: .semibold))
//                                        .foregroundColor(primaryColor)
//                                }
//                            }
//
//                            if viewModel.recentPrescriptions.isEmpty {
//                                emptyStateView(
//                                    icon: "person.2",
//                                    title: "No Doctor Visits",
//                                    message: "Your previously visited doctors will appear here"
//                                )
//                            } else {
//                                ScrollView(.horizontal, showsIndicators: false) {
//                                    HStack(spacing: 16) {
//                                        ForEach(viewModel.recentPrescriptions) { appointment in
//                                            ImprovedDoctorCard(
//                                                name: getDoctorName(for: appointment.docId),
//                                                specialty: "General Medicine",
//                                                lastVisit: formatDate(appointment.date),
//                                                imageName: "defaultDoctorImage"
//                                            )
//                                        }
//                                    }
//                                    .padding(.vertical, 8)
//                                    .padding(.horizontal, 2)
//                                }
//                            }
//                        }
//                    }
//                    .padding(.bottom, 24)
//                }
//                .padding(.leading, 16)
//                .padding(.trailing, 8)
//            }
//            .navigationBarBackButtonHidden(true)
//            .onAppear {
//                if listener == nil {
//                    isLoading = true
//                    loadDoctorData {
//                        setupSnapshotListener()
//                    }
//                }
//                if isInitialLoad {
//                    isInitialLoad = false
//                } else if isVoiceOverEnabled {
//                    readHomeViewText()
//                }
//                print("Recent prescriptions count on appear: \(viewModel.recentPrescriptions.count)")
//            }
//            .onDisappear {
//                listener?.remove()
//                listener = nil
//                speechSynthesizer.stopSpeaking(at: .immediate)
//            }
//            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AppointmentBooked"))) { _ in
//                listener?.remove()
//                listener = nil
//                isLoading = true
//                setupSnapshotListener()
//            }
//            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AppointmentCancelled"))) { _ in
//                listener?.remove()
//                listener = nil
//                isLoading = true
//                setupSnapshotListener()
//            }
//            .navigationDestination(isPresented: $navigateToBooking) {
//                DoctorView(patientId: patient.patientId)
//            }
//            .navigationDestination(isPresented: $navigateToNotifications) {
//                NotificationsView(
//                    upcomingSchedules: upcomingSchedules,
//                    getDoctorName: getDoctorName,
//                    getDoctorSpecialty: getDoctorSpecialty,
//                    formatDate: formatDate
//                )
//            }
//            .onChange(of: isVoiceOverEnabled) { newValue in
//                if newValue {
//                    readHomeViewText()
//                } else {
//                    speechSynthesizer.stopSpeaking(at: .immediate)
//                }
//            }
//        }
//    }
    
    private func prescriptionDestination(for appointment: Appointment) -> some View {
        // Check if prescriptionId exists and create a URL
        guard let prescriptionURL = appointment.prescriptionId,
              let imageUrl = URL(string: prescriptionURL) else {
            return AnyView(
                VStack {
                    Text("Invalid Prescription URL")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    // Debugging: Show the prescriptionId
                    Text("Prescription ID: \(appointment.prescriptionId ?? "nil")")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            )
        }

        return AnyView(
            VStack {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding()
                    case .failure(let error):
                        VStack {
                            Text("Failed to Load Image")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Error: \(error.localizedDescription)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            // Debugging: Show the URL
                            Text("URL: \(imageUrl.absoluteString)")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle("Prescription Image")
            .navigationBarTitleDisplayMode(.inline)
        )
    }
    
    private func medicalTestDestination(for appointment: TestResult) -> some View {
        guard let pdfUrl = URL(string: appointment.pdfUrl) else {
            return AnyView(
                VStack {
                    Text("Unable to Load Medical Test")
                        .font(FontSizeManager.font(for: 18, weight: .bold))
                        .foregroundColor(.primary)
                    Text("The document is not available.")
                        .font(FontSizeManager.font(for: 16, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .onAppear {
                    print("Invalid or malformed test URL for appointment: \(appointment.testName)")
                }
            )
        }

        return AnyView(
            PDFKitView(url: pdfUrl)
                .navigationTitle("Medical Test")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    print("Navigating to PDF view with URL: \(pdfUrl)")
                }
        )
    }
    
    private func readHomeViewText() {
        var textToRead = " Welcome to CareHub. "
        if isLoading {
            textToRead += "Loading."
        } else if upcomingSchedules.isEmpty {
            textToRead += "No Upcoming Appointments."
        } else {
            for appointment in upcomingSchedules {
                textToRead += "Appointment with \(getDoctorName(for: appointment.docId)), \(getDoctorSpecialty(for: appointment.docId)), on \(formatDateTime(appointment.date ?? Date()).date) at \(formatDateTime(appointment.date ?? Date()).time). "
            }
        }
        textToRead += "Recent Prescriptions and Reports. "
        if viewModel.recentPrescriptions.isEmpty {
            textToRead += "No Recent Prescriptions. Your prescriptions will appear here."
        } else {
            for appointment in viewModel.recentPrescriptions {
                textToRead += "\(appointment.description) by \(getDoctorName(for: appointment.docId)), dated \(formatDate(appointment.date)). "
            }
        }
        textToRead += "Previously Visited Doctors. "
        if viewModel.recentPrescriptions.isEmpty {
            textToRead += "No Doctor Visits. Your previously visited doctors will appear here."
        } else {
            for appointment in viewModel.recentPrescriptions {
                textToRead += "\(getDoctorName(for: appointment.docId)), General Medicine, last visit \(formatDate(appointment.date)). "
            }
        }
        speak(text: textToRead)
    }

    private func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        speechSynthesizer.speak(utterance)
    }
    private func sectionHeader<T: View>(title: String, hasContent: Bool, @ViewBuilder action: @escaping () -> T) -> some View {
        HStack {
            Text(title)
                .font(FontSizeManager.font(for: 20, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
            
            if hasContent {
                action()
            }
        }
    }
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundColor(.gray.opacity(0.7))
                    .font(.system(size: FontSizeManager.fontSize(for: 36)))
                
                Text(title)
                    .font(FontSizeManager.font(for: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(FontSizeManager.font(for: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal)
            .background(cardBackground.opacity(0.5))
            .cornerRadius(16)
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    private func loadDoctorData(completion: @escaping () -> Void) {
        DoctorData.fetchDoctors {
            print("Doctor data loaded: \(DoctorData.specialties)")
            completion()
        }
    }
    
    private func setupSnapshotListener() {
        let db = Firestore.firestore()
        let calendar = Calendar.current
        let now = Date()
        let oneMonthFromNow = calendar.date(byAdding: .month, value: 1, to: now) ?? now

        listener = db.collection("appointments")
            .whereField("patientId", isEqualTo: patient.patientId)
            .whereField("status", isEqualTo: "scheduled")
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: now))
            .whereField("date", isLessThan: Timestamp(date: oneMonthFromNow))
            .addSnapshotListener { [self] (querySnapshot, error) in
                if let error = error {
                    print("Error fetching appointments: \(error.localizedDescription)")
                    isLoading = false
                    return
                }
                
                var schedules: [Appointment] = []
                for change in querySnapshot?.documentChanges ?? [] {
                    let documentData = change.document.data()
                    
                    if let apptId = documentData["apptId"] as? String,
                       let patientId = documentData["patientId"] as? String,
                       let description = documentData["description"] as? String,
                       let docId = documentData["docId"] as? String,
                       let status = documentData["status"] as? String,
                       let billingStatus = documentData["billingStatus"] as? String,
                       let amount = documentData["amount"] as? Double,
                       let date = (documentData["date"] as? Timestamp)?.dateValue(),
                       let doctorsNotes = documentData["doctorsNotes"] as? String,
                       let prescriptionId = documentData["prescriptionId"] as? String,
                       let followUpRequired = documentData["followUpRequired"] as? Bool,
                       let followUpDate = (documentData["followUpDate"] as? Timestamp)?.dateValue() {

                        let appointment = Appointment(
                            id: apptId,
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

                        if change.type == .added || change.type == .modified {
                            if !schedules.contains(where: { $0.id == appointment.id }) {
                                schedules.append(appointment)
                            }
                        }
                    } else {
                        print("Missing or invalid fields in document: \(change.document.documentID)")
                    }
                }

                if let documentIds = querySnapshot?.documents.map({ $0.documentID }) {
                    upcomingSchedules.removeAll { !documentIds.contains($0.id) }
                }
                
                upcomingSchedules = schedules.sorted { ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast) }
                
                // Calculate notification count for appointments within 0–48 hours
                let appointmentsWithin48Hours = upcomingSchedules.filter { appointment in
                    guard let date = appointment.date else { return false }
                    let hoursDifference = Calendar.current.dateComponents([.hour], from: now, to: date).hour ?? 0
                    return hoursDifference >= 0 && hoursDifference <= 48
                }
                
                if hasViewedNotifications, let lastViewTime = lastNotificationViewTime {
                    // Only count appointments that are scheduled after the last notification view
                    notificationCount = appointmentsWithin48Hours.filter { appointment in
                        guard let date = appointment.date else { return false }
                        return date > lastViewTime
                    }.count
                } else {
                    // If notifications haven't been viewed, show all appointments within 48 hours
                    notificationCount = appointmentsWithin48Hours.count
                }
                
                isLoading = false
                print("Updated upcomingSchedules: \(upcomingSchedules.count), notificationCount: \(notificationCount), isLoading: \(isLoading)")
            }
    }

    private func getDoctorName(for docId: String) -> String {
        for specialty in DoctorData.doctors.keys {
            if let doctor = DoctorData.doctors[specialty]?.first(where: { $0.id == docId }) {
                return doctor.doctor_name
            }
        }
        return "Unknown Doctor"
    }
    
    private func getDoctorSpecialty(for docId: String) -> String {
        for specialty in DoctorData.doctors.keys {
            if DoctorData.doctors[specialty]?.contains(where: { $0.id == docId }) ?? false {
                return specialty
            }
        }
        return "Unknown Specialty"
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "No date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date?) -> (date: String, time: String) {
        guard let date = date else { return ("No date", "No time") }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, d MMM yyyy"
        let dateStr = dateFormatter.string(from: date)
        
        dateFormatter.dateFormat = "h:mm a"
        let timeStr = dateFormatter.string(from: date)
        
        return (dateStr, timeStr)
    }
}

// MARK: - NotificationsView
struct NotificationsView: View {
    let upcomingSchedules: [Appointment]
    let getDoctorName: (String) -> String
    let getDoctorSpecialty: (String) -> String
    let formatDate: (Date?) -> String
    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    private let backgroundColor = Color(red: 0.94, green: 0.94, blue: 1.0)
    
    @State private var selectedAppointmentForDetails: Appointment?

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                let upcomingIn24to48Hours = upcomingSchedules.filter { appointment in
                    guard let date = appointment.date else { return false }
                    let now = Date()
                    let hoursDifference = Calendar.current.dateComponents([.hour], from: now, to: date).hour ?? 0
                    return hoursDifference >= 0 && hoursDifference <= 48
                }
                
                VStack(spacing: 20) {
                    if upcomingIn24to48Hours.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bell.slash.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray)
                                .font(.system(size: FontSizeManager.fontSize(for: 60)))
                            Text("No Updates")
                                .font(FontSizeManager.font(for: 20, weight: .bold))
                                .foregroundColor(.primary)
                            Text("You have no new notifications.")
                                .font(FontSizeManager.font(for: 16, weight: .regular))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 20)
                        .accessibilityElement(children: .combine)
                    } else {
                        ForEach(upcomingIn24to48Hours) { appointment in
                            NotificationCard(
                                doctorName: getDoctorName(appointment.docId),
                                date: formatDate(appointment.date).components(separatedBy: " at ")[0],
                                time: formatDate(appointment.date).components(separatedBy: " at ")[1]
                            )
                            .padding(.horizontal, 20)
                            .accessibilityLabel("Notification: Appointment with \(getDoctorName(appointment.docId)) on \(formatDate(appointment.date))")
                            .onTapGesture {
                                selectedAppointmentForDetails = appointment
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedAppointmentForDetails) { appointment in
            AppointmentDetailsModal(
                appointment: appointment,
                doctorName: getDoctorName(appointment.docId),
                specialty: getDoctorSpecialty(appointment.docId),
                imageName: "doctor1",
                isPresented: Binding(
                    get: { selectedAppointmentForDetails != nil },
                    set: { if !$0 { selectedAppointmentForDetails = nil } }
                )
            )
        }
    }
}

// MARK: - NotificationCard
struct NotificationCard: View {
    let doctorName: String
    let date: String
    let time: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color(red: 0.43, green: 0.34, blue: 0.99))
                        .clipShape(Circle())
                    
                    Text("You have an upcoming appointment with \(doctorName) at \(time)")
                        .font(FontSizeManager.font(for: 16, weight: .medium))
                        .foregroundColor(.black)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                }
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: FontSizeManager.fontSize(for: 14)))
                        .foregroundColor(.black.opacity(0.6))
                    
                    Text(date)
                        .font(FontSizeManager.font(for: 15, weight: .medium))
                        .foregroundColor(.black.opacity(0.8))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(red: 0.95, green: 0.95, blue: 0.98))
                .cornerRadius(12)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
    }
}

// MARK: - AllAppointmentsView
struct AllAppointmentsView: View {
    @Binding var upcomingSchedules: [Appointment]
    let getDoctorName: (String) -> String
    let getDoctorSpecialty: (String) -> String
    let formatDate: (Date?) -> String
    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    private let backgroundColor = Color(red: 0.97, green: 0.97, blue: 1.0)
    
    var body: some View {
        ZStack {
            backgroundColor
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                if upcomingSchedules.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray.opacity(0.7))
                            .font(.system(size: FontSizeManager.fontSize(for: 60)))
                        
                        Text("No Upcoming Appointments")
                            .font(FontSizeManager.font(for: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("You don't have any scheduled appointments")
                            .font(FontSizeManager.font(for: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 100)
                    .padding(.horizontal)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach($upcomingSchedules) { $appointment in
                                AppointmentListCard(
                                    doctorName: getDoctorName(appointment.docId),
                                    specialty: getDoctorSpecialty(appointment.docId),
                                    date: formatDate(appointment.date),
                                    imageName: "doctor1",
                                    appointment: $appointment
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .padding(.top, 20)
        }
        .navigationTitle("Upcoming Appointments")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDateTime(_ date: Date?) -> (date: String, time: String) {
        guard let date = date else { return ("No date", "No time") }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, d MMM yyyy"
        let dateStr = dateFormatter.string(from: date)
        
        dateFormatter.dateFormat = "h:mm a"
        let timeStr = dateFormatter.string(from: date)
        
        return (dateStr, timeStr)
    }
}

// MARK: - AppointmentListCard
struct AppointmentListCard: View {
    let doctorName: String
    let specialty: String
    let date: String
    let imageName: String
    @Binding var appointment: Appointment
    @State private var showDetails = false
    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    
    var body: some View {
        Button(action: {
            showDetails = true
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                
                HStack(spacing: 16) {
                    Group {
                        if UIImage(named: imageName) != nil {
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                                .foregroundColor(primaryColor)
                                .font(.system(size: FontSizeManager.fontSize(for: 64)))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(doctorName)
                            .font(FontSizeManager.font(for: 16, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(specialty)
                            .font(FontSizeManager.font(for: 14, weight: .regular))
                            .foregroundColor(.secondary)
                        
                        Text(date)
                            .font(FontSizeManager.font(for: 12, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: FontSizeManager.fontSize(for: 16)))
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showDetails) {
            AppointmentDetailsModal(
                appointment: appointment,
                doctorName: doctorName,
                specialty: specialty,
                imageName: imageName,
                isPresented: $showDetails
            )
        }
        .accessibilityLabel("Appointment with \(doctorName) for \(specialty), on \(date)")
    }
}

struct AllPrescriptionsView: View {
    let prescriptions: [Appointment]
    let formatDate: (Date?) -> String
    let viewModel: AppointmentViewModel // Add viewModel as a parameter
    
    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    if prescriptions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.secondary)
                                .font(.system(size: FontSizeManager.fontSize(for: 60)))
                            Text("No Prescriptions Available")
                                .font(FontSizeManager.font(for: 20, weight: .bold))
                                .foregroundColor(.primary)
                            Text("Your prescriptions and reports will appear here once added.")
                                .font(FontSizeManager.font(for: 16, weight: .regular))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 20)
                        .accessibilityElement(children: .combine)
                    } else {
                        ForEach(prescriptions) { appointment in
                            NavigationLink(
                                destination: prescriptionDestination(for: appointment),
                                label: {
                                    ImprovedMedicalRecordCard(
                                        type: appointment.status,
                                        doctorName: "\(getDoctorName(for: appointment.docId))",
                                        date: formatDate(appointment.date),
                                        title: appointment.description
                                    )
                                    .padding(.horizontal, 20)
                                    .accessibilityLabel("Prescription: \(appointment.description) by \(getDoctorName(for: appointment.docId)), dated \(formatDate(appointment.date))")
                                }
                            )
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("All Prescriptions")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func prescriptionDestination(for appointment: Appointment) -> some View {
        Group {
            if let prescriptionURL = appointment.prescriptionId,
               let imageUrl = URL(string: prescriptionURL) {
                AnyView(
                    VStack {
                        AsyncImage(url: imageUrl) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            case .failure:
                                VStack {
                                    Text("Failed to Load Image")
                                        .font(FontSizeManager.font(for: 18, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text("The image could not be retrieved.")
                                        .font(FontSizeManager.font(for: 16, weight: .regular))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    .navigationTitle("Prescription Image")
                    .navigationBarTitleDisplayMode(.inline)
                    .onAppear {
                        print("Navigating to image view with URL: \(imageUrl)")
                    }
                )
            } else {
                AnyView(
                    VStack {
                        Text("Unable to Load Medical Test Report")
                            .font(FontSizeManager.font(for: 18, weight: .bold))
                            .foregroundColor(.primary)
                        Text("The document is not available.")
                            .font(FontSizeManager.font(for: 16, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .onAppear {
                        print("Invalid or missing prescription URL for appointment: \(appointment.description)")
                    }
                )
            }
        }
    }
    
    private func getDoctorName(for docId: String) -> String {
        for specialty in DoctorData.doctors.keys {
            if let doctor = DoctorData.doctors[specialty]?.first(where: { $0.id == docId }) {
                return doctor.doctor_name
            }
        }
        return "Unknown Doctor"
    }
}

//struct AllTestsView: View {
//    let prescriptions: [TestResult]
//    let formatDate: (Date?) -> String
//    let viewModel: AppointmentViewModel // Add viewModel as a parameter
//
//    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
//    var body: some View {
//        ZStack {
//            Color(.systemBackground)
//                .ignoresSafeArea()
//            ScrollView {
//                VStack(spacing: 16) {
//                    if prescriptions.isEmpty {
//                        VStack(spacing: 12) {
//                            Image(systemName: "doc.text.fill")
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: 60, height: 60)
//                                .foregroundColor(.secondary)
//                                .font(.system(size: 60))
//                            Text("No Tests Available")
//                                .font(.system(size: 20, weight: .bold))
//                                .foregroundColor(.primary)
//                            Text("Your reports will appear here once added.")
//                                .font(.system(size: 16, weight: .regular))
//                                .foregroundColor(.secondary)
//                                .multilineTextAlignment(.center)
//                                .padding(.horizontal)
//                        }
//                        .padding(.vertical, 20)
//                        .accessibilityElement(children: .combine)
//                    } else {
//                        ForEach(prescriptions) { testResult in
//                            NavigationLink(
//                                destination: prescriptionDestination(for: testResult),
//                                label: {
//                                    ImprovedMedicalRecordCard(
//                                        type: testResult.status,
//                                        doctorName: testResult.doc,
//                                        date: formatDate(testResult.date),
//                                        title: testResult.testName
//                                    )
//                                    .padding(.horizontal, 20)
//                                    .accessibilityLabel("Test Name: \(testResult.testName) by \(testResult.doc), dated \(formatDate(testResult.date))")
//                                }
//                            )
//                            .buttonStyle(.plain)
//                        }
//                    }
//                }
//                .padding(.top, 20)
//                .padding(.bottom, 20)
//            }
//        }
//        .navigationTitle("All Medical Reports")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//
//    private func prescriptionDestination(for testResult: TestResult) -> some View {
//        if let url = URL(string: testResult.pdfUrl), !testResult.pdfUrl.isEmpty {
//            return AnyView(
//                PDFViewer(pdfUrl: url)
//                    .navigationTitle("Medical Test Report")
//                    .navigationBarTitleDisplayMode(.inline)
//                    .overlay {
//                        ProgressView()
//                            .opacity(url.isFileURL || url.absoluteString.isEmpty ? 0 : 1)
//                    }
//                    .onAppear {
//                        print("Navigating to PDF view with URL: \(url)")
//                    }
//            )
//        } else {
//            return AnyView(
//                VStack {
//                    Text("Unable to Load Medical Test Report")
//                        .font(.system(size: 18, weight: .bold))
//                        .foregroundColor(.primary)
//                    Text("The document is not available.")
//                        .font(.system(size: 16, weight: .regular))
//                        .foregroundColor(.secondary)
//                }
//                .onAppear {
//                    print("Invalid or missing PDF URL for test result: \(testResult.testName)")
//                }
//            )
//        }
//    }
//
//    private func getDoctorName(for docId: String) -> String {
//        for specialty in DoctorData.doctors.keys {
//            if let doctor = DoctorData.doctors[specialty]?.first(where: { $0.id == docId }) {
//                return doctor.doctor_name
//            }
//        }
//        return "Unknown Doctor"
//    }
//}

struct EmptyTestsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.secondary)
                .font(.system(size: 60))
            Text("No Tests Available")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            Text("Your reports will appear here once added.")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 20)
        .accessibilityElement(children: .combine)
    }
}

struct ErrorViewTest: View {
    let testName: String
    
    var body: some View {
        VStack {
            Text("Unable to Load Medical Test Report")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            Text("The document for \(testName) is not available.")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .onAppear {
            print("Invalid or missing PDF URL for test result: \(testName)")
        }
    }
}

struct PDFViewerView: View {
    let pdfUrl: URL
    
    var body: some View {
        PDFViewer(pdfUrl: pdfUrl)
            .navigationTitle("Medical Test Report")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                ProgressView()
                    .opacity(pdfUrl.isFileURL || pdfUrl.absoluteString.isEmpty ? 0 : 1)
            }
            .onAppear {
                print("Navigating to PDF view with URL: \(pdfUrl)")
            }
    }
}

struct TestResultCardPatient: View {
    let testResult: TestResult
    let formatDate: (Date?) -> String
    let destination: AnyView
    
    var body: some View {
        NavigationLink(
            destination: destination,
            label: {
                ImprovedMedicalRecordCard(
                    type: testResult.status,
                    doctorName: testResult.doc,
                    date: testResult.date,
                    title: testResult.testName
                )
                .padding(.horizontal, 20)
                .accessibilityLabel("Test Name: \(testResult.testName) by \(testResult.doc)")
            }
        )
        .buttonStyle(.plain)
    }
}

struct AllTestsView: View {
    let prescriptions: [TestResult]
    let formatDate: (Date?) -> String
    let viewModel: AppointmentViewModel
    
    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    if prescriptions.isEmpty {
                        EmptyTestsView()
                    } else {
                        ForEach(prescriptions) { testResult in
                            TestResultCardPatient(
                                testResult: testResult,
                                formatDate: formatDate,
                                destination: prescriptionDestination(for: testResult)
                            )
                        }
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("All Medical Reports")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func prescriptionDestination(for testResult: TestResult) -> AnyView {
        if let url = URL(string: testResult.pdfUrl), !testResult.pdfUrl.isEmpty {
            return AnyView(PDFViewerView(pdfUrl: url))
        } else {
            return AnyView(ErrorViewTest(testName: testResult.testName))
        }
    }
    
    private func getDoctorName(for docId: String) -> String {
        for specialty in DoctorData.doctors.keys {
            if let doctor = DoctorData.doctors[specialty]?.first(where: { $0.id == docId }) {
                return doctor.doctor_name
            }
        }
        return "Unknown Doctor"
    }
}

// MARK: - ImprovedAppointmentCard
struct ImprovedAppointmentCard: View {
    let doctorName: String
    let specialty: String
    let date: String
    let time: String
    let imageName: String
    @Binding var appointment: Appointment
    @State private var showDetails = false
    private let primaryColor = Color(red: 0.51, green: 0.44, blue: 0.87)
    
    var body: some View {
        Button(action: {
            showDetails = true
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(primaryColor)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Group {
                            if UIImage(named: imageName) != nil {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.white)
                                    .font(.system(size: FontSizeManager.fontSize(for: 50)))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(doctorName)
                                .font(FontSizeManager.font(for: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(specialty)
                                .font(FontSizeManager.font(for: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        HStack(spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.white)
                                    .font(.system(size: FontSizeManager.fontSize(for: 14)))
                                
                                Text(date)
                                    .font(FontSizeManager.font(for: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 8)
                            .padding(.leading, 12)
                            .padding(.trailing, 6)
                            
                            Rectangle()
                                .frame(width: 1, height: 20)
                                .foregroundColor(.white.opacity(0.3))
                                .padding(.horizontal, 4)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .foregroundColor(.white)
                                    .font(.system(size: FontSizeManager.fontSize(for: 14)))
                                
                                Text(time)
                                    .font(FontSizeManager.font(for: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 8)
                            .padding(.leading, 6)
                            .padding(.trailing, 12)
                        }
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(16)
                        
                        Spacer()
                    }
                }
                .padding(16)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(height: 130)
        .sheet(isPresented: $showDetails) {
            AppointmentDetailsModal(
                appointment: appointment,
                doctorName: doctorName,
                specialty: specialty,
                imageName: imageName,
                isPresented: $showDetails
            )
        }
        .accessibilityLabel("Appointment with \(doctorName) for \(specialty), on \(date) at \(time)")
    }
}


struct ImprovedMedicalRecordCard: View {
    let type: String
    let doctorName: String
    let date: String
    let title: String
    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(primaryColor.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "doc.text.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundColor(primaryColor)
                        .font(.system(size: FontSizeManager.fontSize(for: 22)))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(FontSizeManager.font(for: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(doctorName)
                        .font(FontSizeManager.font(for: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Text(date)
                        .font(FontSizeManager.font(for: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.system(size: FontSizeManager.fontSize(for: 14)))
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("\(title) by \(doctorName), dated \(date)")
    }
}

struct DoctorVisit: Identifiable {
    let id: String
    let name: String
    let specialty: String
    let lastVisit: Date
}

struct ImprovedDoctorCard: View {
    let name: String
    let specialty: String
    let lastVisit: String
    let imageName: String
    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .frame(width: 64, height: 64)
                        .foregroundColor(.clear)
                        .overlay(Circle().stroke(primaryColor, lineWidth: 2))
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 40)) // Reduced size of the icon
                        .foregroundColor(primaryColor)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(name)
                        .font(FontSizeManager.font(for: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(specialty)
                        .font(FontSizeManager.font(for: 14, weight: .regular))
                        .foregroundColor(.secondary)
                    
                    Text("Last Visit: \(lastVisit)")
                        .font(FontSizeManager.font(for: 12, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                Spacer()
            
                .accessibilityLabel("Call \(name)")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity)
    }
}
// MARK: - AllVisitedDoctorsView
struct AllVisitedDoctorsView: View {
    let recentPrescriptions: [Appointment]
    let formatDate: (Date?) -> String
    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    private let backgroundColor = Color(red: 0.97, green: 0.97, blue: 1.0)
    
    var body: some View {
        ZStack {
            backgroundColor
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                let uniqueDoctors = getUniqueDoctors()
                VStack(spacing: 16) {
                    if uniqueDoctors.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray.opacity(0.7))
                                .font(.system(size: FontSizeManager.fontSize(for: 60)))
                            
                            Text("No Doctor Visits")
                                .font(FontSizeManager.font(for: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Your previously visited doctors will appear here")
                                .font(FontSizeManager.font(for: 14, weight: .regular))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 100)
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(uniqueDoctors) { doctor in
                                ImprovedDoctorCard(
                                    name: " \(doctor.name)",
                                    specialty: doctor.specialty,
                                    lastVisit: formatDate(doctor.lastVisit),
                                    imageName: "defaultDoctorImage"
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                .padding(.top, 20)
            }
        }
        .navigationTitle("Visited Doctors")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func getDoctorName(for docId: String) -> String {
        for specialty in DoctorData.doctors.keys {
            if let doctor = DoctorData.doctors[specialty]?.first(where: { $0.id == docId }) {
                return doctor.doctor_name
            }
        }
        return "Unknown Doctor"
    }
    
    private func getDoctorSpecialty(for docId: String) -> String {
        for specialty in DoctorData.doctors.keys {
            if DoctorData.doctors[specialty]?.contains(where: { $0.id == docId }) ?? false {
                return specialty
            }
        }
        return "Unknown Specialty"
    }
    
    private func getUniqueDoctors() -> [DoctorVisit] {
        var doctorMap: [String: DoctorVisit] = [:]
        
        for appointment in recentPrescriptions {
            let docId = appointment.docId
            let doctorName = getDoctorName(for: docId)
            let specialty = getDoctorSpecialty(for: docId)
            let visitDate = appointment.date ?? Date.distantPast
            
            if let existing = doctorMap[docId] {
                if visitDate > existing.lastVisit {
                    doctorMap[docId] = DoctorVisit(id: docId, name: doctorName, specialty: specialty, lastVisit: visitDate)
                }
            } else {
                doctorMap[docId] = DoctorVisit(id: docId, name: doctorName, specialty: specialty, lastVisit: visitDate)
            }
        }
        return doctorMap.values.sorted { $0.lastVisit > $1.lastVisit }
    }
}

