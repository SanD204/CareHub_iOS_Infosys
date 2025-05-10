import SwiftUI
import FirebaseAuth

struct LoginView: View {
    enum Role { case patient, staff }
    @State private var selectedRole: Role = .patient
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showAlert = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    @StateObject private var authManager = AuthManager.shared
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        ZStack {
            if authManager.navigateToDashboard {
                dashboardContent
            } else {
                loginContent
            }
        }
    }
    
    private var loginContent: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.4),
                        Color(red: 0.94, green: 0.94, blue: 1.0),
                        Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                // Main content
                VStack(spacing: 25) {
                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text("CareHub")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 50)
                    
                    // Role Picker
                    Picker("Login As", selection: $selectedRole) {
                        Text("Patient").tag(Role.patient)
                        Text("Staff").tag(Role.staff)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    
                    // Form fields
                    VStack(spacing: 20) {
                        CareHubTextField(
                            text: $email,
                            placeholder: selectedRole == .patient ? "Enter your Email ID" : "Enter your Staff ID",
                            isSecure: false,
                            isValid: true,
                            icon: "envelope.fill"
                        )
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        
                        CareHubTextField(
                            text: $password,
                            placeholder: "Enter Password",
                            isSecure: true,
                            isValid: true,
                            icon: "lock.fill"
                        )
                        .textContentType(.password)
                    }
                    .padding(.horizontal, 20)
                    
                    // Login button
                    Button(action: login) {
                        ZStack {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 24)
                            
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Login")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.43, green: 0.34, blue: 0.99),
                                Color(red: 0.55, green: 0.48, blue: 0.99)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .cornerRadius(12)
                        .shadow(color: Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .padding(.horizontal, 20)
                    
                    // Register link (only for patient role)
                    if selectedRole == .patient {
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.black)
                            NavigationLink(destination: RegisterView()) {
                                Text("Register")
                                    .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                                    .underline()
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 10)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationBarBackButtonHidden(true)
            .alert("Login Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error occurred")
            }
            .onChange(of: authManager.errorMessage) { newValue in
                if let newValue = newValue {
                    errorMessage = newValue
                    showAlert = true
                }
            }
            .sheet(isPresented: Binding(
                get: { !appState.hasCompletedOnboarding && !appState.isSplashActive },
                set: { _ in }
            )) {
                OnboardingView()
                    .environmentObject(appState)
            }
        }
    }
    
    @ViewBuilder
    var dashboardContent: some View {
        if authManager.isLoading {
            ProgressView("Loading dashboard...")
        } else {
            // Patient View
            if selectedRole == .patient {
                if let patient = authManager.currentPatient {
                    NavigationStack {
                        PatientTabView(username: patient.userData.Name, patient: patient)
                    }
                } else {
                    noDataFoundView(message: "No patient data found")
                }
            }
            // Doctor View
            else if let doctor = authManager.currentDoctor {
                NavigationStack {
                    DoctorTabView()
                }
            }
            // Other Staff Views
            else if selectedRole == .staff, let staff = authManager.currentStaffMember {
                switch staff.role {
                case .admin:
                    NavigationStack {
                        AdminTabView()
                    }
                case .nurse:
                    NavigationStack {
                        NurseTabView(nurseId: staff.id ?? "")
                    }
                case .labTechnician:
                    NavigationStack {
                        LabTechTabView()
                    }
                case .accountant:
                    NavigationStack {
                        AccountantDashboard(accountantId: staff.id ?? "KV93GmJ9k9VtzHtx0M8p1fH30Mf2")
                    }
                default:
                    noDataFoundView(message: "Role not implemented")
                }
            }
            // Fallback for no data
            else {
                noDataFoundView(message: "No user data found")
            }
        }
    }

    // Helper view for error states
    private func noDataFoundView(message: String) -> some View {
        VStack {
            Text(message)
                .padding()
            Button("Try Again") {
                authManager.logout()
                authManager.navigateToDashboard = false
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password"
            showAlert = true
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters long"
            showAlert = true
            return
        }
        
        isLoading = true
        
        AuthManager.shared.login(email: email, password: password, role: selectedRole) { success in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    // Check for all possible user types
                    if self.selectedRole == .patient {
                        if AuthManager.shared.currentPatient != nil {
                            authManager.navigateToDashboard = true
                        } else {
                            self.errorMessage = "Invalid patient credentials"
                            self.showAlert = true
                        }
                    } else { // For staff or doctor
                        if AuthManager.shared.currentStaffMember != nil ||
                            AuthManager.shared.currentDoctor != nil {
                            authManager.navigateToDashboard = true
                        } else {
                            self.errorMessage = "Invalid credentials"
                            self.showAlert = true
                        }
                    }
                } else {
                    self.errorMessage = AuthManager.shared.errorMessage ?? "Login failed"
                    self.showAlert = true
                }
            }
        }
    }
}
