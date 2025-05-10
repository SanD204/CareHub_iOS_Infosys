import SwiftUI
import CryptoKit

struct CareHubTextField: View {
    @Binding var text: String
    let placeholder: String
    let isSecure: Bool
    var isValid: Bool = true
    let icon: String
   
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                .frame(width: 24)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isValid ? Color.clear : Color.red, lineWidth: isValid ? 0 : 2)
                )
        )
    }
}

struct RegisterView: View {
    enum RegistrationStep: Int {
        case credentials = 1
        case contactInfo
        case personalInfo
        case emailVerification
        
        var progress: Double {
            return Double(rawValue) / 4.0
        }
        
        var title: String {
            switch self {
            case .credentials: return "Create Account"
            case .contactInfo: return "Contact Information"
            case .personalInfo: return "Personal Information"
            case .emailVerification: return "Verify Email"
            }
        }
        
        var subtitle: String {
            switch self {
            case .credentials: return "Let's get started with your account"
            case .contactInfo: return "How can we reach you?"
            case .personalInfo: return "Your personal and health background"
            case .emailVerification: return "Please verify your email address"
            }
        }
        
        var icon: String {
            switch self {
            case .credentials: return "person.crop.circle.badge.plus"
            case .contactInfo: return "phone.fill"
            case .personalInfo: return "heart.text.square.fill"
            case .emailVerification: return "envelope.fill"
            }
        }
    }
    
    @State private var currentStep: RegistrationStep = .credentials
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var dob = ""
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var phoneNo = ""
    @State private var address = ""
    @State private var aadharNo = ""
    @State private var emergencyContacts: [EmergencyContact] = []
    @State private var newContactName = ""
    @State private var newContactNumber = ""
    @State private var previousProblems = ""
    @State private var allergies = ""
    @State private var medications = ""
    @State private var generatedID = ""
    @State private var showAlert = false
    @State private var navigateToLogin = false
    @State private var navigateToHome = false
    @State private var registeredPatient: PatientF?
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    // Field validation states
    @State private var isFirstNameValid = true
    @State private var isLastNameValid = true
    @State private var isEmailValid = true
    @State private var isPasswordValid = true
    @State private var isDobValid = true
    @State private var isPhoneValid = true
    @State private var isAddressValid = true
    @State private var isDatePickerExpanded = false
    
    private let purpleColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    private let gradientColors = [
        Color(red: 0.43, green: 0.34, blue: 0.99),
        Color(red: 0.55, green: 0.48, blue: 0.99)
    ]
    
    private var computedFullName: String {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespaces)
        return trimmedFirst.isEmpty && trimmedLast.isEmpty ? "" : "\(trimmedFirst) \(trimmedLast)".trimmingCharacters(in: .whitespaces)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
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
                
                VStack(spacing: 0) {
                    VStack(spacing: 5) {
                        ProgressView(value: currentStep.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: purpleColor))
                            .padding(.horizontal)
                        
                        HStack {
                            Text("Step \(currentStep.rawValue) of 4")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: currentStep.icon)
                                .font(.system(size: 24))
                                .foregroundColor(purpleColor)
                            Text(currentStep.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)
                        }
                        Text(currentStep.subtitle)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    ScrollView {
                        VStack(spacing: 25) {
                            switch currentStep {
                            case .credentials: credentialsStep
                            case .contactInfo: contactInfoStep
                            case .personalInfo: personalInfoStep
                            case .emailVerification: emailVerificationStep
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                    }
                    
                    Spacer()
                    
                    Button(action: handleNextButton) {
                        HStack {
                            Text(currentStep == .emailVerification ? "Verify Email" : currentStep == .personalInfo ? "Complete Registration" : "Continue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            Image(systemName: currentStep == .emailVerification ? "checkmark.shield.fill" : currentStep == .personalInfo ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .leading, endPoint: .trailing)
                                .cornerRadius(12)
                                .shadow(color: purpleColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarBackButtonHidden(true)
            .alert("Registration Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView()
            }
            .navigationDestination(isPresented: $navigateToHome) {
                if let patient = registeredPatient {
                    HomeView_patient(patient: patient)
                        .navigationBarBackButtonHidden(true)
                }
            }
            .sheet(isPresented: $showDatePicker) {
                VStack {
                    DatePicker("Select Date of Birth", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                        .accentColor(purpleColor)
                        .padding()
                    
                    Button(action: {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "dd/MM/yyyy"
                        dob = dateFormatter.string(from: selectedDate)
                        isDobValid = true
                        showDatePicker = false
                    }) {
                        Text("Done")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .leading, endPoint: .trailing)
                                    .cornerRadius(12)
                                    .shadow(color: purpleColor.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .presentationDetents([.height(300)])
            }
        }
    }
    
    private var credentialsStep: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 12) {
                    CareHubTextField(text: $firstName, placeholder: "First Name", isSecure: false, isValid: isFirstNameValid, icon: "person.fill")
                        .accessibilityLabel("First Name")
                        .onChange(of: firstName) { newValue in
                            isFirstNameValid = validateName(newValue)
                            fullName = computedFullName
                        }
                    
                    CareHubTextField(text: $lastName, placeholder: "Last Name", isSecure: false, isValid: isLastNameValid, icon: "person.fill")
                        .accessibilityLabel("Last Name")
                        .onChange(of: lastName) { newValue in
                            isLastNameValid = validateName(newValue)
                            fullName = computedFullName
                        }
                }
                
                CareHubTextField(text: $email, placeholder: "Email", isSecure: false, isValid: isEmailValid, icon: "envelope.fill")
                    .accessibilityLabel("Email")
                    .onChange(of: email) { newValue in
                        isEmailValid = validateEmail(newValue)
                    }
                
                CareHubTextField(text: $password, placeholder: "Password", isSecure: true, isValid: isPasswordValid, icon: "lock.fill")
                    .accessibilityLabel("Password")
                    .onChange(of: password) { newValue in
                        isPasswordValid = validatePassword(newValue)
                    }
            }
            
            HStack {
                Text("Already have an account?")
                    .foregroundColor(.black)
                Button(action: { navigateToLogin = true }) {
                    Text("Login")
                        .foregroundColor(purpleColor)
                        .underline()
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Login Page Link")
            }
            .padding(.top, 10)
        }
    }
    
    private var contactInfoStep: some View {
        VStack(spacing: 20) {
            CareHubTextField(text: $phoneNo, placeholder: "Phone Number", isSecure: false, isValid: isPhoneValid, icon: "phone.fill")
                .keyboardType(.phonePad)
                .accessibilityLabel("Phone Number")
                .onChange(of: phoneNo) { _ in isPhoneValid = validatePhone(phoneNo) }
            
            CareHubTextField(text: $address, placeholder: "Address", isSecure: false, isValid: isAddressValid, icon: "house.fill")
                .accessibilityLabel("Address")
                .onChange(of: address) { _ in isAddressValid = true }
            
            CareHubTextField(text: $aadharNo, placeholder: "ABHA ID (Optional)", isSecure: false, isValid: true, icon: "creditcard.fill")
                .keyboardType(.numberPad)
                .accessibilityLabel("Aadhar Number")
            
            VStack(alignment: .leading, spacing: 15) {
                VStack(spacing: 70) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 18))
                            .foregroundColor(purpleColor)
                        Text("Emergency Contacts")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                    }
                }
                
                if !emergencyContacts.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(emergencyContacts) { contact in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(contact.name)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black)
                                    Text(contact.Number)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        emergencyContacts.removeAll { $0.id == contact.id }
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.system(size: 22))
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.97, green: 0.97, blue: 1.0))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(red: 0.9, green: 0.9, blue: 1.0), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
                
                VStack(spacing: 20) {
                    CareHubTextField(text: $newContactName, placeholder: "Contact Name", isSecure: false, isValid: true, icon: "person.fill")
                        .accessibilityLabel("New Contact Name")
                    
                    CareHubTextField(text: $newContactNumber, placeholder: "Contact Number", isSecure: false, isValid: newContactNumber.isEmpty || validatePhone(newContactNumber), icon: "phone.fill")
                        .keyboardType(.phonePad)
                        .accessibilityLabel("New Contact Number")
                    
                    Button(action: {
                        if !newContactName.isEmpty && validatePhone(newContactNumber) {
                            withAnimation {
                                emergencyContacts.append(EmergencyContact(Number: newContactNumber, name: newContactName))
                                newContactName = ""
                                newContactNumber = ""
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Contact")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .leading, endPoint: .trailing)
                                .cornerRadius(10)
                                .opacity((newContactName.isEmpty || !validatePhone(newContactNumber)) ? 0.6 : 1)
                        )
                        .disabled(newContactName.isEmpty || !validatePhone(newContactNumber))
                    }
                }
            }
        }
    }
    
    private var personalInfoStep: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(purpleColor)
                    Text("Date of Birth")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
                
                VStack {
                    if !isDatePickerExpanded {
                        Button(action: {
                            withAnimation {
                                isDatePickerExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Text(dob.isEmpty ? "Select Date" : formattedDate(selectedDate))
                                    .foregroundColor(dob.isEmpty ? .gray : .black)
                                    .font(.system(size: 16))
                                Spacer()
                                Image(systemName: "calendar")
                                    .foregroundColor(purpleColor)
                                    .font(.system(size: 14))
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isDobValid ? Color.clear : Color.red, lineWidth: isDobValid ? 0 : 2)
                                    )
                            )
                        }
                        .accessibilityLabel("Date of Birth")
                    } else {
                        VStack {
                            DatePicker("Select Date", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .accentColor(purpleColor)
                                .padding(.top, 8)
                                .onChange(of: selectedDate) { newDate in
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = "dd/MM/yyyy"
                                    dob = dateFormatter.string(from: newDate)
                                    isDobValid = true
                                }
                            
                            Button(action: {
                                withAnimation {
                                    isDatePickerExpanded.toggle()
                                }
                            }) {
                                Text("Done")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .leading, endPoint: .trailing)
                                            .cornerRadius(10)
                                            .shadow(color: purpleColor.opacity(0.3), radius: 4, x: 0, y: 2)
                                    )
                            }
                            .padding(.top, 12)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isDobValid ? Color.clear : Color.red, lineWidth: isDobValid ? 0 : 2)
                                )
                        )
                    }
                }
            }
            
            CareHubTextField(text: $previousProblems, placeholder: "Any Previous Health Problems (Optional)", isSecure: false, isValid: true, icon: "lungs.fill")
                .accessibilityLabel("Previous Problems")
            
            CareHubTextField(text: $allergies, placeholder: "Allergies (Optional)", isSecure: false, isValid: true, icon: "allergens")
                .accessibilityLabel("Allergies")
            
            CareHubTextField(text: $medications, placeholder: "Current Medications (Optional)", isSecure: false, isValid: true, icon: "pills.fill")
                .accessibilityLabel("Medications")
            
            if !fullName.isEmpty && !email.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Registration Summary")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(purpleColor)
                    
                    VStack(spacing: 14) {
                        summaryRow(icon: "person.fill", title: "Name", value: fullName)
                        summaryRow(icon: "envelope.fill", title: "Email", value: email)
                        if !dob.isEmpty {
                            summaryRow(icon: "calendar", title: "Date of Birth", value: dob)
                        }
                        if !phoneNo.isEmpty {
                            summaryRow(icon: "phone.fill", title: "Phone", value: phoneNo)
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
            }
        }
    }
    
    private var emailVerificationStep: some View {
        VStack(spacing: 20) {
            Text("We’ve sent a verification email to \(email).")
                .font(.system(size: 16))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            Text("Please click the link in the email to verify your account.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: {
                AuthManager.shared.sendEmailVerification { success, errorMessage in
                    DispatchQueue.main.async {
                        if !success {
                            showAlert = true
                            self.errorMessage = errorMessage ?? "Failed to resend verification email"
                        } else {
                            showAlert = true
                            self.errorMessage = "Verification email resent. Please check your inbox or spam folder."
                        }
                    }
                }
            }) {
                Text("Resend Verification Email")
                    .font(.system(size: 16))
                    .foregroundColor(purpleColor)
                    .underline()
            }
            .accessibilityLabel("Resend Verification Email")
        }
        .padding(.horizontal, 20)
    }
    
    private func summaryRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(purpleColor)
                .frame(width: 20)
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
                .lineLimit(1)
            Spacer()
        }
    }
    
    private func resetValidationStates() {
        isFirstNameValid = true
        isLastNameValid = true
        isEmailValid = true
        isPasswordValid = true
        isDobValid = true
        isPhoneValid = true
        isAddressValid = true
    }
    
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case .credentials:
            let firstNameValid = validateName(firstName)
            let lastNameValid = validateName(lastName)
            let emailValid = validateEmail(email)
            let passValid = validatePassword(password)
            
            isFirstNameValid = firstNameValid
            isLastNameValid = lastNameValid
            isEmailValid = emailValid
            isPasswordValid = passValid
            
            if !firstNameValid {
                errorMessage = "Please enter a valid first name."
            } else if !lastNameValid {
                errorMessage = "Please enter a valid last name."
            } else if !emailValid {
                errorMessage = "Please enter a valid email address."
            } else if !passValid {
                errorMessage = "Password must be at least 6 characters long and contain no spaces."
            }
            
            return firstNameValid && lastNameValid && emailValid && passValid
            
        case .contactInfo:
            let phoneValid = validatePhone(phoneNo)
            let addressValid = !address.trimmingCharacters(in: .whitespaces).isEmpty
            
            isPhoneValid = phoneValid
            isAddressValid = addressValid
            
            if !phoneValid {
                errorMessage = "Please enter a valid phone number."
            } else if !addressValid {
                errorMessage = "Please enter your address."
            }
            
            return phoneValid && addressValid
            
        case .personalInfo:
            isDobValid = !dob.trimmingCharacters(in: .whitespaces).isEmpty
            if !isDobValid {
                errorMessage = "Please select your date of birth."
            }
            return isDobValid
            
        case .emailVerification:
            return true
        }
    }
    
    private func validateName(_ name: String) -> Bool {
        let nameRegex = "^[a-zA-Z\\s-]+$"
        let namePredicate = NSPredicate(format: "SELF MATCHES %@", nameRegex)
        return namePredicate.evaluate(with: name.trimmingCharacters(in: .whitespaces)) && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func validateEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email.trimmingCharacters(in: .whitespaces)) && !email.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func validatePhone(_ phone: String) -> Bool {
        let phoneRegex = "^[0-9]{10}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
    
    private func validatePassword(_ password: String) -> Bool {
        let trimmedPassword = password.trimmingCharacters(in: .whitespaces)
        return !trimmedPassword.isEmpty && trimmedPassword.count >= 6 && !trimmedPassword.contains(" ")
    }

    private func calculateAge(from dob: String) -> Int? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        guard let birthDate = dateFormatter.date(from: dob) else { return nil }
        let currentDate = DateComponents(year: 2025, month: 4, day: 24).date!
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: birthDate, to: currentDate)
        return components.year
    }
    
    private func handleNextButton() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        let isValid = validateCurrentStep()
        
        if !isValid {
            showAlert = true
            return
        }
        
        if currentStep == .personalInfo {
            generatedID = generateUniqueID(name: fullName, role: "Patient")
            let patient = PatientF(
                emergencyContact: emergencyContacts,
                medicalRecords: [],
                testResults: [],
                userData: UserData(
                    Address: address,
                    Dob: dob,
                    Email: email,
                    Name: fullName,
                    Password: password,
                    aadharNo: aadharNo,
                    phoneNo: phoneNo
                ),
                vitals: Vitals(
                    allergies: allergies.isEmpty ? [] : allergies.components(separatedBy: ", "),
                    bp: [],
                    heartRate: [],
                    height: [],
                    temperature: [],
                    weight: []
                ),
                lastModified: Date(),
                patientId: generatedID
            )
            AuthManager.shared.registerPatient(patient: patient, password: password) { success in
                DispatchQueue.main.async {
                    if success {
                        self.registeredPatient = patient
                        withAnimation {
                            currentStep = .emailVerification
                            resetValidationStates()
                        }
                    } else {
                        showAlert = true
                        errorMessage = AuthManager.shared.errorMessage ?? "Registration failed"
                    }
                }
            }
        } else if currentStep == .emailVerification {
            AuthManager.shared.checkEmailVerification { isVerified, errorMessage in
                DispatchQueue.main.async {
                    if isVerified {
                        navigateToHome = true
                    } else {
                        showAlert = true
                        self.errorMessage = errorMessage ?? "Email not yet verified. Please check your inbox or spam folder."
                    }
                }
            }
        } else {
            withAnimation {
                currentStep = RegistrationStep(rawValue: currentStep.rawValue + 1) ?? .credentials
                resetValidationStates()
            }
        }
    }
    
    private func generateUniqueID(name: String, role: String) -> String {
        let cleanedName = name.trimmingCharacters(in: .whitespaces).lowercased()
        let cleanedRole = role.trimmingCharacters(in: .whitespaces).lowercased()
        if cleanedName.isEmpty || cleanedRole.isEmpty {
            return ""
        }
        let input = "\(cleanedName)_\(cleanedRole)"
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
        let numericHash = Int(hashString.prefix(10), radix: 16) ?? 0
        let sixDigitNumber = String(format: "%06d", numericHash % 1_000_000)
        let rolePrefix = cleanedRole.prefix(1).uppercased()
        return "\(rolePrefix)\(sixDigitNumber)"
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
