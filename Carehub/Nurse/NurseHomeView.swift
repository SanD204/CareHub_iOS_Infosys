import SwiftUI
import Firebase

struct NurseHomeView: View {
    @StateObject private var viewModel = NurseHomeViewModel()
    @Environment(\.colorScheme) private var colorScheme
    var nurseId: String
    
    // Colors
    let primaryColor = Color(red: 109/255, green: 87/255, blue: 252/255)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(colorScheme == .dark ? .black : .systemGray6)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Search Bar
//                    searchBar
                    
                    // Appointments List
                    if viewModel.filteredAppointments.isEmpty {
                        emptyStateView
                    } else {
                        appointmentsListView
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Today's Appointments")
            .onAppear {
                viewModel.fetchAppointments() // Fetch all appointments for today
            }
            .refreshable {
                viewModel.fetchAppointments()
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(primaryColor)
            
            TextField("Search by patient or doctor", text: $viewModel.searchText)
                .padding(.leading, 4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(colorScheme == .dark ? .systemGray5 : .white))
        )
        .padding(.horizontal)
        .onChange(of: viewModel.searchText) { _ in
            viewModel.filterAppointments()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "calendar.badge.clock")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundColor(primaryColor.opacity(0.7))
            
            Text("No appointments found")
                .font(.headline)
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
    
    private var appointmentsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                let timeSlots = getSortedTimeSlots()
                
                ForEach(timeSlots, id: \.self) { timeSlot in
                    timeSlotSection(for: timeSlot)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func getSortedTimeSlots() -> [String] {
        let groupedAppointments = Dictionary(grouping: viewModel.filteredAppointments) { appointment in
            guard let date = appointment.date else { return "Unknown Time" }
            return timeString(from: date)
        }
        
        return groupedAppointments.keys.sorted { time1, time2 in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "h:mmKW a"
            guard let date1 = dateFormatter.date(from: time1),
                  let date2 = dateFormatter.date(from: time2) else {
                return time1 < time2
            }
            return date1 < date2
        }
    }

    @ViewBuilder
    private func timeSlotSection(for timeSlot: String) -> some View {
        let appointments = viewModel.filteredAppointments.filter { appointment in
            guard let date = appointment.date else { return false }
            return timeString(from: date) == timeSlot
        }
        
        if !appointments.isEmpty {
            Section {
                ForEach(appointments) { appt in
                    NurseAppointmentCard(
                        appt: appt,
                        viewModel: viewModel, // Pass viewModel to handle async name fetching
                        primaryColor: primaryColor
                    )
                }
            } header: {
                sectionHeader(for: timeSlot)
            }
        }
    }
    
    private func sectionHeader(for timeSlot: String) -> some View {
        HStack {
            Text(timeSlot)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(primaryColor)
                .padding(.vertical, 4)
            
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.top, 16)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct NurseAppointmentCard: View {
    let appt: Appointment
    let viewModel: NurseHomeViewModel // Use viewModel for async name fetching
    let primaryColor: Color
    @Environment(\.colorScheme) private var colorScheme
    @State private var showDetails = false
    @State private var patientName: String = "Loading..."
    @State private var doctorName: String = "Loading..."
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status and time
            HStack {
                StatusBadge(status: appt.status)
                
//                if let date = appt.date {
//                    Text(timeRemaining(from: date))
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
                
                Spacer()
            }
            
            // Patient and doctor info
            VStack(alignment: .leading, spacing: 8) {
                LabeledContent(label: "Patient", content: patientName)
                LabeledContent(label: "Doctor", content: doctorName)
                
                if !appt.description.isEmpty {
                    Divider()
                    Text(appt.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            // Actions
            HStack {
                Button(action: {
                    showDetails = true
                }) {
                    Label("Update Vitals", systemImage: "heart.text.square")
                        .font(.footnote)
                        .fontWeight(.medium)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(colorScheme == .dark ? .systemGray6 : .white))
                .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 2)
        )
        .sheet(isPresented: $showDetails) {
            NurseVitalsEntryView(patientId: appt.patientId)
        }
        .onAppear {
            // Fetch patient and doctor names asynchronously
            viewModel.getPatientName(for: appt.patientId) { name in
                patientName = name
            }
            viewModel.getDoctorName(for: appt.docId) { name in
                doctorName = name
            }
        }
    }
    
    private func timeRemaining(from date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: Date(), to: date)
        
        if let hours = components.hour, let minutes = components.minute {
            if hours > 0 {
                return "in \(hours)h \(abs(minutes))m"
            } else if minutes > 0 {
                return "in \(minutes)m"
            } else {
                return "now"
            }
        }
        return ""
    }
}

struct PersonRow: View {
    let icon: String
    let name: String
    let role: String
    let primaryColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(primaryColor)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(primaryColor.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(role)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct LabeledContent: View {
    let label: String
    let content: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 55, alignment: .leading)
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

struct StatusBadge: View {
    let status: String
    
    var statusColor: Color {
        switch status.lowercased() {
        case "scheduled": return .blue
        case "checked in": return .green
        case "in progress": return .orange
        case "completed": return .gray
        case "cancelled": return .red
        case "paid": return Color(UIColor.systemGreen)
        case "pending": return .orange
        case "unpaid": return .red
        default: return .blue
        }
    }
    
    var body: some View {
        Text(status)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.15))
            )
            .foregroundColor(statusColor)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                Capsule()
                    .fill(color)
                    .opacity(configuration.isPressed ? 0.8 : 1)
            )
            .foregroundColor(.white)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                Capsule()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    .opacity(configuration.isPressed ? 0.8 : 1)
            )
            .foregroundColor(.primary)
    }
}
