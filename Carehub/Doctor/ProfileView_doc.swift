import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct Qualification {
    let degree: String
    let institution: String
    let years: String
    let description: String
}

struct ProfileView_doc: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var doctor: Doctor? = nil
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var doctorId: String = ""
    @State private var patientCount: Int = 0
    @State private var appointments: [Appointment] = []
    @Binding var showChangePasswordCard: Bool
    @Binding var oldPassword: String
    @Binding var newPassword: String
    @Binding var reEnterNewPassword: String
    @Binding var passwordErrorMessage: String?
    @Binding var showConfirmPasswordChangeAlert: Bool
    @Binding var showLogoutAlert: Bool
    @Binding var logoutErrorMessage: String?
    @Binding var isLoggedOut: Bool
    private let purpleColor = Color(hex: "6D57FC")
    private let lightPurple = Color(hex: "6D57FC").opacity(0.1)
    private let darkPurple = Color(hex: "4A3FC7")
    private let backgroundColor = Color(hex: "F6F7FF")
    private let db = Firestore.firestore()

    private var currentMonthAppointments: [Appointment] {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        return appointments.filter { appointment in
            guard let date = appointment.date else { return false }
            let appointmentMonth = calendar.component(.month, from: date)
            let appointmentYear = calendar.component(.year, from: date)
            return appointmentMonth == currentMonth && appointmentYear == currentYear
        }
    }

    private var totalAppointments: Int { currentMonthAppointments.count }
    private var completedAppointments: Int {
        currentMonthAppointments.filter { $0.status.lowercased() == "completed" }.count
    }

    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all)
            
            // Main content
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let doctor = doctor {
                VStack(spacing: 16) {
                    ProfileHeaderView(doctor: doctor, purpleColor: purpleColor, darkPurple: darkPurple)
                    DoctorIDCardView(doctor: doctor, purpleColor: purpleColor)
                    StatsView(doctor: doctor, purpleColor: purpleColor, patientCount: patientCount)
                    MonthlySummaryView(
                        totalAppointments: totalAppointments,
                        completedAppointments: completedAppointments,
                        purpleColor: purpleColor,
                        lightPurple: lightPurple
                    )
                    Spacer() // Push content up and fill remaining space
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .font(.system(size: 18, weight: .medium))
            }
            
            // Three-dot menu button in top-right corner
            if !isLoading && doctor != nil {
                VStack {
                    HStack {
                        Spacer()
                        Menu {
                            Button(action: {
                                showChangePasswordCard = true
                                oldPassword = ""
                                newPassword = ""
                                reEnterNewPassword = ""
                                passwordErrorMessage = nil
                            }) {
                                Text("Change Password")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            Button(action: {
                                authManager.logout()
                                isLoggedOut = true
                            }) {
                                Text("Log Out")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(purpleColor)
                                .font(.system(size: 20, weight: .bold))
                                .padding(8)
                                .background(Circle().fill(purpleColor.opacity(0.1)))
                        }
                        .padding(.top, 12)
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
            }
            
            // Change Password Card
            if showChangePasswordCard {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showChangePasswordCard = false
                    }
                
                VStack(spacing: 20) {
                    Text("Change Password")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                    
                    if let errorMessage = passwordErrorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 14, weight: .medium))
                    }
                    
                    VStack(spacing: 16) {
                        SecureField("Old Password", text: $oldPassword)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 4)
                            .font(.system(size: 16))
                        
                        SecureField("New Password", text: $newPassword)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 4)
                            .font(.system(size: 16))
                        
                        SecureField("Re-enter New Password", text: $reEnterNewPassword)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 4)
                            .font(.system(size: 16))
                    }
                    
                    Button(action: {
                        passwordErrorMessage = nil
                        if oldPassword.isEmpty || newPassword.isEmpty || reEnterNewPassword.isEmpty {
                            passwordErrorMessage = "All fields are required."
                            return
                        }
                        if newPassword != reEnterNewPassword {
                            passwordErrorMessage = "New passwords do not match."
                            return
                        }
                        if newPassword == oldPassword {
                            passwordErrorMessage = "New password must be different from the old password."
                            return
                        }
                        showConfirmPasswordChangeAlert = true
                    }) {
                        Text("Save")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(purpleColor)
                            .cornerRadius(10)
                            .shadow(color: purpleColor.opacity(0.4), radius: 6)
                    }
                }
                .padding(20)
                .background(Color(hex: "F6F7FF"))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 10)
                .padding(.horizontal, 30)
            }
        }
        .onAppear { fetchDoctorData() }
        .onReceive(authManager.$currentStaffMember) { _ in fetchDoctorData() }
        .alert(isPresented: $showLogoutAlert) {
            Alert(
                title: Text("Logout Failed"),
                message: Text(logoutErrorMessage ?? "An error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $showConfirmPasswordChangeAlert) {
            Alert(
                title: Text("Confirm"),
                message: Text("Are you sure you want to change your password?"),
                primaryButton: .default(Text("Yes")) {
                    proceedWithPasswordUpdate()
                },
                secondaryButton: .cancel(Text("No"))
            )
        }
        .fullScreenCover(isPresented: $isLoggedOut) { LoginView() }
    }

    private func fetchDoctorData() {
        isLoading = true
        guard let uid = Auth.auth().currentUser?.uid else {
            doctorId = ""
            doctor = nil
            isLoading = false
            errorMessage = "User not logged in"
            isLoggedOut = true
            return
        }

        db.collection("doctors").document(uid).getDocument { snapshot, error in
            defer { isLoading = false }
            if let error = error {
                doctorId = ""
                doctor = nil
                errorMessage = error.localizedDescription
                return
            }

            guard let document = snapshot, document.exists, let data = document.data(),
                  let docId = data["Doctorid"] as? String else {
                doctorId = ""
                doctor = nil
                errorMessage = "Doctor data not found"
                return
            }

            doctorId = docId
            let experience = data["Doctor_experience"] as? Double ?? Double(data["Doctor_experience"] as? Int ?? 0)
            doctor = Doctor(
                id: docId,
                department: data["department"] as? String ?? (data["Filed_name"] as? String ?? ""),
                doctor_name: data["Doctor_name"] as? String ?? "",
                doctor_experience: Int(experience),
                email: data["Email"] as? String,
                imageURL: data["ImageURL"] as? String,
                consultationFee: Int(data["consultationFee"] as? Double ?? 0.0),
                license_number: data["license_number"] as? String,
                phoneNo: data["phoneNo"] as? String,
                doctorsNotes: nil
            )
            fetchPatientCount()
            fetchAppointments()
        }
    }

    private func fetchPatientCount() {
        guard !doctorId.isEmpty else { patientCount = 0; return }
        db.collection("appointments")
            .whereField("docId", isEqualTo: doctorId)
            .getDocuments { snapshot, error in
                if let error = error {
                    patientCount = 0
                    return
                }
                let patientIds = Set(snapshot?.documents.compactMap { $0.data()["patientId"] as? String } ?? [])
                patientCount = patientIds.count
            }
    }

    private func fetchAppointments() {
        guard !doctorId.isEmpty else { appointments = []; return }
        db.collection("appointments")
            .whereField("docId", isEqualTo: doctorId)
            .getDocuments { snapshot, error in
                if let error = error {
                    appointments = []
                    return
                }
                appointments = snapshot?.documents.compactMap { doc -> Appointment? in
                    let data = doc.data()
                    guard let apptId = data["apptId"] as? String,
                          let patientId = data["patientId"] as? String,
                          let docId = data["docId"] as? String,
                          let description = (data["description"] as? String) ?? (data["Description"] as? String),
                          let status = (data["status"] as? String) ?? (data["Status"] as? String) else {
                        return nil
                    }
                    return Appointment(
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
                } ?? []
            }
    }

    private func updatePassword() {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            passwordErrorMessage = "User not logged in or email not found."
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                passwordErrorMessage = "Old password is incorrect: \(error.localizedDescription)"
                return
            }

            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    passwordErrorMessage = "Failed to update password: \(error.localizedDescription)"
                    return
                }

                showChangePasswordCard = false
            }
        }
    }

    private func proceedWithPasswordUpdate() {
        updatePassword()
    }
}

struct ProfileHeaderView: View {
    let doctor: Doctor
    let purpleColor: Color
    let darkPurple: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(purpleColor)
            Text(doctor.doctor_name)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.black)
            Text(doctor.department)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(darkPurple)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct DoctorIDCardView: View {
    let doctor: Doctor
    let purpleColor: Color

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [purpleColor, purpleColor.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .shadow(color: purpleColor.opacity(0.2), radius: 8)
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DOCTOR ID")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    Text(doctor.id)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("LICENSE NO")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    Text(doctor.license_number ?? "N/A")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: 150)
    }
}

struct StatsView: View {
    let doctor: Doctor
    let purpleColor: Color
    let patientCount: Int

    var body: some View {
        HStack(spacing: 12) {
            StatView(icon: "person.2.fill", value: "\(patientCount)", label: "Patients", color: purpleColor)
            StatView(icon: "clock.fill", value: "\(doctor.doctor_experience ?? 0) Yrs", label: "Experience", color: purpleColor)
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: purpleColor.opacity(0.1), radius: 8)
        )
    }
}

struct MonthlySummaryView: View {
    let totalAppointments: Int
    let completedAppointments: Int
    let purpleColor: Color
    let lightPurple: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Monthly Summary")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.black)
            HStack(spacing: 12) {
                SummaryItem(value: "\(totalAppointments)", label: "Appointments", icon: "calendar", color: purpleColor)
                SummaryItem(value: "\(completedAppointments)", label: "Completed", icon: "checkmark.circle.fill", color: purpleColor)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(lightPurple)
                .shadow(color: purpleColor.opacity(0.1), radius: 8)
        )
    }
}

struct StatView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.black)
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(color.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

struct SummaryItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.black)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(color.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}
