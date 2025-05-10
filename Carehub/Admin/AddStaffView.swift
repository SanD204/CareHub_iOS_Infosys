import SwiftUI

struct AddStaffView: View {
    @ObservedObject var staffManager: StaffManager
    @Environment(\.dismiss) var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var selectedRole: StaffRole = .doctor
    @State private var department = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var shiftStartTime = Date()
    @State private var shiftEndTime = Date()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var profileImage: UIImage?
    @State private var showImagePicker = false
    @State private var showingSuccessAlert = false
    
    // Doctor-specific fields
    @State private var doctorExperience = ""
    @State private var licenseNumber = ""
    @State private var consultationFee = ""
    
    // UI Constants
    private let accentColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    private let gradientColors = [Color(red: 0.43, green: 0.34, blue: 0.99), Color(red: 0.55, green: 0.48, blue: 0.99)]
    private let backgroundColor = Color(red: 0.97, green: 0.97, blue: 1.0)
    private let cardBackgroundColor = Color.white
    private let textFieldBackground = Color(red: 0.96, green: 0.96, blue: 0.98)
    
    let departments = ["Cardiology", "Neurology", "Pediatrics", "Oncology", "Radiology", "Pathology", "Emergency"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Personal Information Section
                        formSection(title: "Personal Information") {
                            customTextField(title: "Full Name", text: $fullName, iconName: "person")
                            customTextField(title: "Email", text: $email, iconName: "envelope")
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            customTextField(title: "Phone Number", text: $phoneNumber, iconName: "phone")
                                .keyboardType(.phonePad)
                        }
                        
                        // Professional Information Section
                        formSection(title: "Professional Information") {
                            rolePicker
                            
                            if selectedRole == .doctor || selectedRole == .nurse {
                                departmentPicker
                            }
                            
                            // Doctor-specific fields
                            if selectedRole == .doctor {
                                customTextField(title: "Years of Experience", text: $doctorExperience, iconName: "calendar.badge.clock")
                                    .keyboardType(.numberPad)
                                
                                customTextField(title: "License Number", text: $licenseNumber, iconName: "doc.text")
                                
                                customTextField(title: "Consultation Fee", text: $consultationFee, iconName: "dollarsign.circle")
                                    .keyboardType(.numberPad)
                            }
                        }
                        
                        // Shift Information Section
                        formSection(title: "Shift Information") {
                            shiftTimePicker
                        }
                        
                        // Account Credentials Section
                        formSection(title: "Account Credentials") {
                            customSecureField(title: "Password", text: $password, iconName: "lock")
                            customSecureField(title: "Confirm Password", text: $confirmPassword, iconName: "lock.shield")
                        }
                        
                        // Save Button
                        saveButton
                            .padding(.vertical, 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 15)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Add New Staff")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(accentColor)
                }
            }
            .alert("Validation Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $profileImage)
            }
        }
        .alert("Saved Successfully", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss() // Navigates back to the Admin Dashboard
            }
        }
    }

    
    // MARK: - UI Components
    
    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.35))
                .padding(.leading, 4)
            
            VStack(spacing: 14) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackgroundColor)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    private func customTextField(title: String, text: Binding<String>, iconName: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.45))
            
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .foregroundColor(accentColor.opacity(0.6))
                    .frame(width: 20)
                
                TextField("", text: text)
                    .font(.system(size: 16))
            }
            .padding(12)
            .background(textFieldBackground)
            .cornerRadius(10)
        }
    }
    
    private func customSecureField(title: String, text: Binding<String>, iconName: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.45))
            
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .foregroundColor(accentColor.opacity(0.6))
                    .frame(width: 20)
                
                SecureField("", text: text)
                    .font(.system(size: 16))
            }
            .padding(12)
            .background(textFieldBackground)
            .cornerRadius(10)
        }
    }
    
    private var rolePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Role")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.45))
            
            HStack {
                Image(systemName: "person.text.rectangle")
                    .foregroundColor(accentColor.opacity(0.6))
                    .frame(width: 20)
                
                Picker("", selection: $selectedRole) {
                    ForEach(StaffRole.allCases) { role in
                        Text(role.rawValue).tag(role)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(textFieldBackground)
            .cornerRadius(10)
        }
    }
    
    private var departmentPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Department")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.45))
            
            HStack {
                Image(systemName: "building.2")
                    .foregroundColor(accentColor.opacity(0.6))
                    .frame(width: 20)
                
                Picker("", selection: $department) {
                    Text("Select Department").tag("")
                    ForEach(departments, id: \.self) { dept in
                        Text(dept).tag(dept)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(textFieldBackground)
            .cornerRadius(10)
        }
    }
    
    private var shiftTimePicker: some View {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Shift Start Time")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.45))
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(accentColor.opacity(0.6))
                            .frame(width: 20)
                        
                        DatePicker("", selection: $shiftStartTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .background(textFieldBackground)
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Shift End Time")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.45))
                    
                    HStack {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundColor(accentColor.opacity(0.6))
                            .frame(width: 20)
                        
                        DatePicker("", selection: $shiftEndTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .background(textFieldBackground)
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
    
    private var saveButton: some View {
        Button(action: saveStaff) {
            Text("Save")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    formIsValid ?
                    LinearGradient(gradient: Gradient(colors: gradientColors),
                                  startPoint: .leading,
                                  endPoint: .trailing) :
                    LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.5)]),
                                  startPoint: .leading,
                                  endPoint: .trailing)
                )
                .cornerRadius(12)
                .shadow(color: formIsValid ? accentColor.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 3)
                .animation(.easeInOut(duration: 0.2), value: formIsValid)
        }
        .disabled(!formIsValid)
    }
    
    // MARK: - Logic (unchanged)
    
    var formIsValid: Bool {
        // Common validation
        let commonValid = !fullName.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        !phoneNumber.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        (selectedRole != .doctor && selectedRole != .nurse || !department.isEmpty)
        
        // Doctor-specific validation
        if selectedRole == .doctor {
            return commonValid &&
            !doctorExperience.isEmpty &&
            !licenseNumber.isEmpty &&
            !consultationFee.isEmpty
        }
        
        return commonValid
    }
    
    private func saveStaff() {
        guard formIsValid else {
            alertMessage = "Please fill all fields with valid information"
            showingAlert = true
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match"
            showingAlert = true
            return
        }
        
        // Generate ID based on role
        let prefix: String
        switch selectedRole {
        case .doctor: prefix = "D"
        case .nurse: prefix = "N"
        case .labTechnician: prefix = "LT"
        case .accountant: prefix = "ACC"
        case .admin: prefix = "M"
        }
        
        let randomNumbers = String(format: "%05d", Int.random(in: 0..<100000))
        let staffId = prefix + randomNumbers
        
        if selectedRole == .doctor {
            // Create Doctor object
            let newDoctor = Doctor(
                id: staffId,
                department: department,
                doctor_name: fullName,
                doctor_experience: Int(doctorExperience),
                email: email,
                imageURL: nil, // Will be set after image upload
                password: password,
                consultationFee: Int(consultationFee),
                license_number: licenseNumber,
                phoneNo: phoneNumber,
                doctorsNotes: nil
            )
            
            staffManager.addDoctor(newDoctor) { success in
                handleSaveResult(success: success)
            }
          
        } else {
            // Create generic Staff object for other roles
            let newStaff = Staff(
                id: staffId,
                fullName: fullName,
                email: email,
                role: selectedRole,
                department: (selectedRole == .doctor || selectedRole == .nurse) ? department : nil,
                phoneNumber: phoneNumber,
                joinDate: Date(),
                profileImageURL: nil,
                shift: Shift(startTime: shiftStartTime, endTime: shiftEndTime)
            )
            
            staffManager.addStaff(newStaff, password: password) { success in
                handleSaveResult(success: success)
            }
        }
    }
    
    private func handleSaveResult(success: Bool) {
        if success {
            showingSuccessAlert = true
        } else {
            alertMessage = staffManager.errorMessage ?? "Failed to add staff"
            showingAlert = true
        }
    }
}

// Helper view for sections
struct SectionView<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
                .padding(.top, 8)
            
            VStack(spacing: 16) {
                content()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}
    
    struct StaffDetailView: View {
        @State var staff: Staff
        @ObservedObject var staffManager: StaffManager
        @Environment(\.dismiss) var dismiss
        @State private var isEditing = false
        @State private var showingDeleteAlert = false
        private let purpleColor = Color(red: 0.43, green: 0.34, blue: 0.99)
        private let gradientColors = [Color(red: 0.43, green: 0.34, blue: 0.99), Color(red: 0.55, green: 0.48, blue: 0.99)]
        let departments = ["Cardiology", "Neurology", "Pediatrics", "Oncology", "Radiology", "Pathology", "Emergency"]
        
        var body: some View {
            ZStack {
                Color(red: 0.94, green: 0.94, blue: 1.0)
                    .edgesIgnoringSafeArea(.all)
                
                Group {
                    if isEditing {
                        editForm
                    } else {
                        detailList
                    }
                }
                .navigationTitle(isEditing ? "Edit Staff" : staff.fullName)
                .navigationBarTitleDisplayMode(isEditing ? .inline : .large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if isEditing {
                            Button("Done") {
                                staffManager.updateStaff(staff) { success in
                                    if success {
                                        isEditing = false
                                    }
                                }
                            }
                            .foregroundColor(purpleColor)
                        } else {
                            Button("Edit") {
                                isEditing = true
                            }
                            .foregroundColor(purpleColor)
                        }
                    }
                }
                .alert("Delete Staff", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        staffManager.deleteStaff(staff) { success in
                            if success {
                                dismiss()
                            }
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete \(staff.fullName)? This action cannot be undone.")
                }
            }
        }
        
        private var editForm: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                    .padding(.horizontal, 20)
                Form {
                    Section(header: Text("Personal Information")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)) {
                            TextField("Full Name", text: $staff.fullName)
                            TextField("Email", text: $staff.email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                    
                    Section(header: Text("Professional Information")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)) {
                            Picker("Role", selection: $staff.role) {
                                ForEach(StaffRole.allCases) { role in
                                    Text(role.rawValue).tag(role)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .disabled(true)
                            
                            Picker("Department", selection: $staff.department) {
                                ForEach(departments, id: \.self) { dept in
                                    Text(dept).tag(dept)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    
                    Section {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Staff", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                .background(Color.clear)
            }
            .padding(.top, 10)
        }
        
        private var detailList: some View {
            VStack(spacing: 15) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                    VStack(spacing: 20) {
                        HStack {
                            Spacer()
                            StaffAvatarView(role: staff.role)
                                .frame(width: 100, height: 100)
                            Spacer()
                        }
                    }
                    .padding()
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                    VStack(spacing: 10) {
                        InfoRow(label: "Staff ID", value: staff.id ?? "123")
                        InfoRow(label: "Role", value: staff.role.rawValue)
                        InfoRow(label: "Department", value: staff.department ?? "N/A")
                    }
                    .padding()
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                    VStack(spacing: 10) {
                        InfoRow(label: "Full Name", value: staff.fullName)
                        InfoRow(label: "Email", value: staff.email)
                        InfoRow(label: "Phone", value: staff.phoneNumber ?? "123-123-123")
                    }
                    .padding()
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                    VStack(spacing: 10) {
                        InfoRow(label: "Join Date", value: staff.joinDate?.formatted(date: .long, time: .omitted) ?? "N/A")
                    }
                    .padding()
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // StaffAvatarView.swift
    struct StaffAvatarView: View {
        let role: StaffRole
        
        var color: Color {
            switch role {
            case .doctor: return .green
            case .nurse: return .orange
            case .labTechnician: return .purple
            case .admin: return .blue
            case .accountant: return .yellow
            }
        }
        
        var icon: String {
            switch role {
            case .doctor: return "stethoscope"
            case .nurse: return "cross.case.fill"
            case .labTechnician: return "testtube.2"
            case .admin: return "person.fill"
            case .accountant: return "person.crop.circle.fill"
            }
        }
        
        var body: some View {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
        }
    }
    
    // InfoRow.swift
    struct InfoRow: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack {
                Text(label)
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
