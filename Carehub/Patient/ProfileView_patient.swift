import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AVFoundation


// MARK: - Settings View
struct SettingsView_patient: View {
    let patient: PatientF
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToLogin = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.94, green: 0.94, blue: 1.0)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Patient Name Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 16) {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
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
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(patient.userData.Name)
                                        .font(FontSizeManager.font(for: 24, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                        // Options Section - Now with individual cards for each option
                        VStack(spacing: 16) {
                            NavigationLink(destination: ProfileDetailView(patient: patient)) {
                                SettingsOptionCard(title: "Profile", icon: "person.fill")
                            }
                            
                            NavigationLink(destination: AccessibilityView()) {
                                SettingsOptionCard(title: "Accessibility and VoiceOver", icon: "gearshape.fill")
                            }
                            
                            NavigationLink(destination: ResetPasswordView()) {
                                SettingsOptionCard(title: "Reset Password", icon: "lock.fill")
                            }
                            
                            Button(action: {
                                AuthManager.shared.logout()
                                navigateToLogin = true
                            }) {
                                SettingsOptionCard(title: "Log Out", icon: "arrow.right.circle", textColor: .red)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.large)
                .fullScreenCover(isPresented: $navigateToLogin) {
                    LoginView()
                }
            }
        }
    }
}

// MARK: - Settings Option Card
struct SettingsOptionCard: View {
    let title: String
    let icon: String
    var textColor: Color = Color(red: 0.43, green: 0.34, blue: 0.99)

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(FontSizeManager.font(for: 18))
                .foregroundColor(textColor)
                .frame(width: 30, height: 30)
            
            Text(title)
                .font(FontSizeManager.font(for: 18, weight: .medium))
                .foregroundColor(textColor)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(FontSizeManager.font(for: 14))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Profile Detail View
struct ProfileDetailView: View {
    let patient: PatientF

    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.94, blue: 1.0)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Personal Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Personal Information")
                            .font(FontSizeManager.font(for: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                            .padding(.horizontal, 16)
                        
                        ProfileRow(title: "Patient ID", value: patient.patientId, icon: "person.text.rectangle.fill")
                        ProfileRow(title: "Date of Birth", value: patient.userData.Dob, icon: "calendar")
                        ProfileRow(title: "Email", value: patient.userData.Email, icon: "envelope.fill")
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

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contact Information")
                            .font(FontSizeManager.font(for: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                            .padding(.horizontal, 16)
                        
                        ProfileRow(title: "Phone Number", value: patient.userData.phoneNo, icon: "phone.fill")
                        ProfileRow(title: "Address", value: patient.userData.Address, icon: "house.fill")
                        ProfileRow(title: "Aadhar Number", value: patient.userData.aadharNo.isEmpty ? "Not Provided" : patient.userData.aadharNo, icon: "person.text.rectangle")
                        
                        MultiItemProfileRow(
                            title: "Emergency Contacts",
                            value: patient.emergencyContact.map { "\($0.name) (\($0.Number))" }.joined(separator: ", "),
                            icon: "person.fill"
                        )
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

                    // Medical Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Medical Information")
                            .font(FontSizeManager.font(for: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                            .padding(.horizontal, 16)
                        
                        MultiItemProfileRow(
                            title: "Allergies",
                            value: patient.vitals.allergies.joined(separator: ", "),
                            icon: "allergens"
                        )
                        
                        ProfileRow(
                            title: "Latest Blood Pressure",
                            value: patient.vitals.bp.last?.value ?? "Not Recorded",
                            icon: "heart.fill"
                        )
                        
                        ProfileRow(
                            title: "Latest Heart Rate",
                            value: patient.vitals.heartRate.last?.value ?? "Not Recorded",
                            icon: "heart.fill"
                        )
                        
                        ProfileRow(
                            title: "Latest Height",
                            value: patient.vitals.height.last?.value ?? "Not Recorded",
                            icon: "ruler"
                        )
                        
                        ProfileRow(
                            title: "Latest Temperature",
                            value: patient.vitals.temperature.last?.value ?? "Not Recorded",
                            icon: "thermometer"
                        )
                        
                        ProfileRow(
                            title: "Latest Weight",
                            value: patient.vitals.weight.last?.value ?? "Not Recorded",
                            icon: "scalemass"
                        )
                        
                        ProfileRow(
                            title: "Last Updated",
                            value: formatDate(patient.lastModified),
                            icon: "clock.fill"
                        )
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
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: EditProfileView(patient: patient)) {
                        Text("Edit")
                            .font(FontSizeManager.font(for: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                    }
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Accessibility View
struct AccessibilityView: View {
    @AppStorage("isLargeFontEnabled") private var isLargeFontEnabled = false
    @AppStorage("isVoiceOverEnabled") private var isVoiceOverEnabled = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var isInitialLoad = true

    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.94, blue: 1.0)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    

                    Toggle(isOn: $isLargeFontEnabled) {
                        Label("Large Font Size", systemImage: "textformat.size")
                            .font(FontSizeManager.font(for: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                    )

                    Toggle(isOn: $isVoiceOverEnabled) {
                        Label("VoiceOver (Read Aloud)", systemImage: "speaker.wave.2.fill")
                            .font(FontSizeManager.font(for: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                    )
                    .onChange(of: isVoiceOverEnabled) { newValue in
                        if newValue {
                            readAccessibilityText()
                        } else {
                            speechSynthesizer.stopSpeaking(at: .immediate)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Accessibility")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if isInitialLoad {
                isInitialLoad = false
            } else if isVoiceOverEnabled {
                readAccessibilityText()
            }
        }
        .onDisappear {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }

    private func readAccessibilityText() {
        let textToRead = "Accessibility. Large Font Size \(isLargeFontEnabled ? "Enabled" : "Disabled"). VoiceOver \(isVoiceOverEnabled ? "Enabled" : "Disabled")."
        speak(text: textToRead)
    }

    private func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        speechSynthesizer.speak(utterance)
    }
}

// MARK: - Reset Password View
// MARK: - Reset Password View
struct ResetPasswordView: View {
    @State private var oldPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isLoading: Bool = false
    @State private var showConfirmationAlert: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.94, blue: 1.0)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reset Password")
                            .font(FontSizeManager.font(for: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                            .padding(.horizontal, 16)
                        
                        Text("Please enter your current password and then set a new password.")
                            .font(FontSizeManager.font(for: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)

                        // Old Password Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Password")
                                .font(FontSizeManager.font(for: 14, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                            
                            SecureField("Current Password", text: $oldPassword)
                                .font(FontSizeManager.font(for: 16))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                        }
                        .padding(.top, 8)

                        // New Password Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("New Password")
                                .font(FontSizeManager.font(for: 14, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                            
                            SecureField("New Password", text: $newPassword)
                                .font(FontSizeManager.font(for: 16))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                        }
                        .padding(.top, 8)

                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Confirm New Password")
                                .font(FontSizeManager.font(for: 14, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                            
                            SecureField("Confirm New Password", text: $confirmPassword)
                                .font(FontSizeManager.font(for: 16))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                        }
                        .padding(.top, 8)

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(FontSizeManager.font(for: 14))
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                        }

                        if let successMessage = successMessage {
                            Text(successMessage)
                                .font(FontSizeManager.font(for: 14))
                                .foregroundColor(.green)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                        }

                        Button(action: {
                            validateAndShowConfirmation()
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            } else {
                                Text("Update Password")
                                    .font(FontSizeManager.font(for: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                        }
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.43, green: 0.34, blue: 0.99),
                                    Color(red: 0.55, green: 0.48, blue: 0.99)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                        .shadow(color: Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.3), radius: 5, x: 0, y: 3)
                        .padding(.vertical, 8)
                        .disabled(isLoading)
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
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.large)
            .alert("Are you sure?", isPresented: $showConfirmationAlert) {
                Button("No", role: .cancel) { }
                Button("Yes") {
                    updatePassword()
                }
            } message: {
                Text("Do you want to update your password?")
            }
        }
    }
    
    private func validateAndShowConfirmation() {
        // Reset messages
        errorMessage = nil
        
        // Validate inputs
        guard !oldPassword.isEmpty else {
            errorMessage = "Please enter your current password."
            return
        }
        
        guard !newPassword.isEmpty else {
            errorMessage = "Please enter a new password."
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "New passwords do not match."
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters long."
            return
        }
        
        // If all validations pass, show confirmation alert
        showConfirmationAlert = true
    }

    private func updatePassword() {
        // Reset messages
        errorMessage = nil
        successMessage = nil
        
        // Validate inputs
        guard !oldPassword.isEmpty else {
            errorMessage = "Please enter your current password."
            return
        }
        
        guard !newPassword.isEmpty else {
            errorMessage = "Please enter a new password."
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "New passwords do not match."
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters long."
            return
        }
        
        isLoading = true
        
        // Get the current user
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No user is currently signed in."
            isLoading = false
            return
        }
        
        // Get the user's email
        guard let email = user.email else {
            errorMessage = "User email not found."
            isLoading = false
            return
        }
        
        // Re-authenticate the user
        let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
        
        user.reauthenticate(with: credential) { authResult, error in
            if let error = error {
                // Handle re-authentication error
                DispatchQueue.main.async {
                    errorMessage = "Current password is incorrect: \(error.localizedDescription)"
                    isLoading = false
                }
                return
            }
            
            // Update the password
            user.updatePassword(to: newPassword) { error in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    if let error = error {
                        // Handle password update error
                        errorMessage = "Failed to update password: \(error.localizedDescription)"
                    } else {
                        // Password updated successfully - update local data if needed
                        if var patient = AuthManager.shared.currentPatient {
                            patient.userData.Password = newPassword
                            AuthManager.shared.currentPatient = patient
                            
                            // Update in Firestore if needed
                            let db = Firestore.firestore()
                            do {
                                try db.collection("patients").document(user.uid).updateData([
                                    "userData.Password": newPassword
                                ])
                            } catch {
                                print("Error updating password in Firestore: \(error.localizedDescription)")
                            }
                        }
                        
                        successMessage = "Password updated successfully!"
                        
                        // Clear password fields
                        oldPassword = ""
                        newPassword = ""
                        confirmPassword = ""
                        
                        // Dismiss the view after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
struct ProfileRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(FontSizeManager.font(for: 14))
                .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                .frame(width: 24)
            
            Text(title)
                .font(FontSizeManager.font(for: 16, weight: .medium))
                .foregroundColor(.black)
            
            Spacer()
            
            Text(value)
                .font(FontSizeManager.font(for: 15, weight: .regular))
                .foregroundColor(.gray)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

// MARK: - MultiItemProfileRow (Reused)
struct MultiItemProfileRow: View {
    let title: String
    let value: String
    let icon: String
    
    private var items: [String] {
        if value.isEmpty {
            return ["None"]
        } else {
            return value.components(separatedBy: ", ")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(FontSizeManager.font(for: 14))
                    .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                    .frame(width: 24)
                
                Text(title)
                    .font(FontSizeManager.font(for: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Spacer()
            }
            
            if items.count == 1 {
                Text(items[0])
                    .font(FontSizeManager.font(for: 16, weight: .regular))
                    .foregroundColor(.gray)
                    .padding(.leading, 36)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        Text(item)
                            .font(FontSizeManager.font(for: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(red: 0.95, green: 0.95, blue: 1.0))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(red: 0.85, green: 0.85, blue: 1.0), lineWidth: 1)
                            )
                    }
                }
                .padding(.leading, 36)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

// MARK: - FlowLayout (Reused)
struct FlowLayout: Layout {
    var spacing: CGFloat = 10
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            if x + viewSize.width > width {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            
            maxHeight = max(maxHeight, viewSize.height)
            x += viewSize.width + spacing
            height = max(height, y + maxHeight)
        }
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            if x + viewSize.width > bounds.maxX {
                x = bounds.minX
                y += maxHeight + spacing
                maxHeight = 0
            }
            
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: viewSize.width, height: viewSize.height))
            maxHeight = max(maxHeight, viewSize.height)
            x += viewSize.width + spacing
        }
    }
}

// MARK: - EditProfileView (Reused)
struct EditProfileView: View {
    let patient: PatientF
    @State private var fullName: String
    @State private var email: String
    @State private var dob: String
    @State private var phoneNo: String
    @State private var address: String
    @State private var aadharNo: String
    @State private var emergencyContacts: [EmergencyContact]
    @State private var allergies: [String]
    @Environment(\.dismiss) private var dismiss
    
    private let db = Firestore.firestore()
    
    init(patient: PatientF) {
        self.patient = patient
        self._fullName = State(initialValue: patient.userData.Name)
        self._email = State(initialValue: patient.userData.Email)
        self._dob = State(initialValue: patient.userData.Dob)
        self._phoneNo = State(initialValue: patient.userData.phoneNo)
        self._address = State(initialValue: patient.userData.Address)
        self._aadharNo = State(initialValue: patient.userData.aadharNo)
        self._emergencyContacts = State(initialValue: patient.emergencyContact)
        self._allergies = State(initialValue: patient.vitals.allergies)
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.94, blue: 1.0)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 16) {
                    personalInfoSection
                    contactInfoSection
                    medicalInfoSection
                    saveButton
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Information")
                .font(FontSizeManager.font(for: 18, weight: .bold))
                .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Name")
                    .font(FontSizeManager.font(for: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                
                TextField("Full Name", text: $fullName)
                    .font(FontSizeManager.font(for: 16))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(FontSizeManager.font(for: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                
                TextField("Email", text: $email)
                    .font(FontSizeManager.font(for: 16))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Date of Birth (DD/MM/YYYY)")
                    .font(FontSizeManager.font(for: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                
                TextField("Date of Birth", text: $dob)
                    .font(FontSizeManager.font(for: 16))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
            }
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
    
    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Information")
                .font(FontSizeManager.font(for: 18, weight: .bold))
                .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Phone Number")
                    .font(FontSizeManager.font(for: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                
                TextField("Phone Number", text: $phoneNo)
                    .font(FontSizeManager.font(for: 16))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Address")
                    .font(FontSizeManager.font(for: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                
                TextField("Address", text: $address)
                    .font(FontSizeManager.font(for: 16))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Aadhar Number (Optional)")
                    .font(FontSizeManager.font(for: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                
                TextField("Aadhar Number", text: $aadharNo)
                    .font(FontSizeManager.font(for: 16))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
            }
            
            EditableEmergencyContactsSection(
                title: "Emergency Contacts",
                contacts: $emergencyContacts
            )
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
    
    private var medicalInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Medical Information")
                .font(FontSizeManager.font(for: 18, weight: .bold))
                .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                .padding(.horizontal, 16)
                .padding(.top, 8)
            
            EditableItemsSection(
                title: "Allergies",
                placeholder: "Allergy",
                items: $allergies,
                addButtonLabel: "Add Allergy"
            )
            .animation(nil, value: allergies)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var saveButton: some View {
        Button(action: {
            guard let user = Auth.auth().currentUser else {
                print("No authenticated user found")
                return
            }
            
            let updatedPatient = PatientF(
                emergencyContact: emergencyContacts,
                medicalRecords: patient.medicalRecords,
                testResults: patient.testResults,
                userData: UserData(
                    Address: address,
                    Dob: dob,
                    Email: email,
                    Name: fullName,
                    Password: patient.userData.Password,
                    aadharNo: aadharNo,
                    phoneNo: phoneNo
                ),
                vitals: Vitals(
                    allergies: allergies,
                    bp: patient.vitals.bp,
                    heartRate: patient.vitals.heartRate,
                    height: patient.vitals.height,
                    temperature: patient.vitals.temperature,
                    weight: patient.vitals.weight
                ),
                lastModified: Date(),
                patientId: patient.patientId
            )
            
            do {
                try db.collection("patients").document(user.uid).setData(from: updatedPatient) { error in
                    if let error = error {
                        print("Error saving patient data: \(error.localizedDescription)")
                    } else {
                        print("Patient data updated successfully")
                        AuthManager.shared.currentPatient = updatedPatient
                        dismiss()
                    }
                }
            } catch {
                print("Error encoding patient data: \(error.localizedDescription)")
            }
        }) {
            Text("Save Changes")
                .font(FontSizeManager.font(for: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.43, green: 0.34, blue: 0.99),
                            Color(red: 0.55, green: 0.48, blue: 0.99)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
                .shadow(color: Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - EditableEmergencyContactsSection (Reused)
struct EditableEmergencyContactsSection: View {
    let title: String
    @Binding var contacts: [EmergencyContact]
    @State private var newContactName: String = ""
    @State private var newContactNumber: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(FontSizeManager.font(for: 16, weight: .medium))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
            
            ForEach(contacts) { contact in
                HStack {
                    VStack(alignment: .leading) {
                        TextField("Name", text: .constant(contact.name))
                            .font(FontSizeManager.font(for: 16))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                            .disabled(true)
                        
                        TextField("Number", text: .constant(contact.Number))
                            .font(FontSizeManager.font(for: 16))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                            .disabled(true)
                    }
                    
                    Button(action: {
                        contacts.removeAll { $0.id == contact.id }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: FontSizeManager.fontSize(for: 22)))
                    }
                    .padding(.trailing, 8)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("New Contact Name", text: $newContactName)
                    .font(FontSizeManager.font(for: 16))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                
                TextField("New Contact Number", text: $newContactNumber)
                    .font(FontSizeManager.font(for: 16))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
            }
            
            Button(action: {
                if !newContactName.isEmpty && !newContactNumber.isEmpty {
                    contacts.append(EmergencyContact(Number: newContactNumber, name: newContactName))
                    newContactName = ""
                    newContactNumber = ""
                }
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Contact")
                }
                .font(FontSizeManager.font(for: 16, weight: .medium))
                .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - EditableItemsSection (Reused)
struct EditableItemsSection: View {
    let title: String
    let placeholder: String
    @Binding var items: [String]
    let addButtonLabel: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(FontSizeManager.font(for: 16, weight: .medium))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
            
            if items.isEmpty {
                addButton
            } else {
                ForEach(items.indices, id: \.self) { index in
                    itemRow(for: index)
                }
                
                addButton
            }
        }
    }
    
    private func itemRow(for index: Int) -> some View {
        HStack {
            TextField(placeholder, text: $items[index])
                .font(FontSizeManager.font(for: 16))
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
            
            Button(action: {
                items.remove(at: index)
            }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: FontSizeManager.fontSize(for: 22)))
            }
            .padding(.trailing, 8)
        }
    }
    
    private var addButton: some View {
        Button(action: {
            items.append("")
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: FontSizeManager.fontSize(for: 16)))
                Text(addButtonLabel)
                    .font(FontSizeManager.font(for: 16, weight: .medium))
            }
            .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
    }
}
