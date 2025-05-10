import SwiftUI

struct AdminProfileView: View {
    @State private var admin: Staff
    @State private var isEditing = false
    @State private var tempName: String
    @State private var tempEmail: String
    @State private var tempPhone: String
    @State private var showLoginView = false
    private let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    private let gradientColors = [Color(red: 0.43, green: 0.34, blue: 0.99), Color(red: 0.55, green: 0.48, blue: 0.99)]

    init(admin: Staff) {
        self._admin = State(initialValue: admin)
        self._tempName = State(initialValue: admin.fullName)
        self._tempEmail = State(initialValue: admin.email)
        self._tempPhone = State(initialValue: admin.phoneNumber ?? "12345")
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.94, green: 0.94, blue: 1.0)
                    .edgesIgnoringSafeArea(.all)

                Group {
                    if isEditing {
                        editProfileView
                    } else {
                        profileView
                    }
                }
                .navigationTitle("Profile")
//                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if isEditing {
                            Button("Done") {
                                saveChanges()
                                isEditing = false
                            }
                            .foregroundColor(primaryColor)
                            .font(.system(size: 16, weight: .medium))
                        } else {
                            Button("Edit") {
                                isEditing = true
                            }
                            .foregroundColor(primaryColor)
                            .font(.system(size: 16, weight: .medium))
                        }
                    }
                }
                .fullScreenCover(isPresented: $showLoginView) {
                    LoginView()
                }
            }
        }
    }

    private var profileView: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Header Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: gradientColors),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: primaryColor.opacity(0.3), radius: 5, x: 0, y: 3)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(admin.fullName)
                                .font(.system(size: 20, weight: .semibold))
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

                // Staff Info Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Staff Information")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(primaryColor)
                        .padding(.horizontal, 16)

                    ProfileRow3(title: "Staff ID", value: admin.id ?? "123", icon: "person.text.rectangle.fill")
                    ProfileRow3(title: "Role", value: admin.role.rawValue, icon: "person.fill")
                    ProfileRow3(title: "Department", value: admin.department ?? "N/A", icon: "building.fill")
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

                // Contact Info Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Contact Information")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(primaryColor)
                        .padding(.horizontal, 16)

                    ProfileRow3(title: "Full Name", value: admin.fullName, icon: "person.fill")
                    ProfileRow3(title: "Email", value: admin.email, icon: "envelope.fill")
                    ProfileRow3(title: "Phone Number", value: admin.phoneNumber ?? "123456", icon: "phone.fill")
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

                // Logout Button
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: {
                        AuthManager.shared.logout()
                        showLoginView = true
                    }) {
                        Label("Log Out", systemImage: "arrow.right.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
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

                Spacer()
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
    }

    private var editProfileView: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Personal Information Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Personal Information")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(primaryColor)
                        .padding(.horizontal, 16)

                    EditProfileRow(label: "Full Name", text: $tempName)
                    EditProfileRow(label: "Email", text: $tempEmail, keyboardType: .emailAddress)
                    EditProfileRow(label: "Phone Number", text: $tempPhone, keyboardType: .phonePad)
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

                // Action Buttons
                VStack(spacing: 8) {
                    Button(action: {
                        saveChanges()
                        isEditing = false
                    }) {
                        Text("Save Changes")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: gradientColors),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                            .shadow(color: primaryColor.opacity(0.3), radius: 5, x: 0, y: 3)
                    }

                    Button(action: {
                        isEditing = false
                        resetTempValues()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
    }

    private func saveChanges() {
        admin.fullName = tempName
        admin.email = tempEmail
        admin.phoneNumber = tempPhone
    }

    private func resetTempValues() {
        tempName = admin.fullName
        tempEmail = admin.email
        tempPhone = admin.phoneNumber ?? "12345"
    }
}

// MARK: - ProfileRow for consistent styling
struct ProfileRow3: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                .frame(width: 24)

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.gray)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

// MARK: - EditProfileRow for edit mode
struct EditProfileRow: View {
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)

            TextField(label, text: $text)
                .font(.system(size: 16))
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
        }
    }
}
