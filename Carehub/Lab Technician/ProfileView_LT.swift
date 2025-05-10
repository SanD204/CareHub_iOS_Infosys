import SwiftUI

// Lab Technician Model
struct LabTechnician1: Codable {
    let fullName: String
    let id: String
    let department: String
    let email: String
    let phoneNumber: String
    let joinDate: Date

    enum CodingKeys: String, CodingKey {
        case fullName
        case id
        case department
        case email
        case phoneNumber
        case joinDate
    }
}

// ViewModel for fetching Lab Technician data
class LabTechViewModel: ObservableObject {
    @Published var labTech: LabTechnician1?
    @Published var isLoading = false
    @Published var error: Error?

    func fetchLabTech(byId: String) {
        isLoading = true
        error = nil

        // Simulated API call (replace with actual API call or Firestore fetch)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            // Mock data
            let mockLabTech = LabTechnician1(
                fullName: "Sanyog Dani",
                id: "LT001",
                department: "Pathology",
                email: "t1@gmail.com",
                phoneNumber: "9816578234",
                joinDate: {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMMM d, yyyy 'at' h:mm:ss a 'UTC'Z"
                    formatter.timeZone = TimeZone(secondsFromGMT: 5 * 3600 + 30 * 60) // UTC+5:30
                    return formatter.date(from: "April 26, 2025 at 10:32 PM") ?? Date()
                }()
            )
            self.labTech = mockLabTech
        }
    }
}

struct ProfileView_LT: View {
    let labTechId: String
    @StateObject private var viewModel = LabTechViewModel()
    let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    @State private var showLoginView = false
    @State private var isLoggingOut = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.94, green: 0.94, blue: 1.0)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView("Loading profile...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let labTech = viewModel.labTech {
                        // Contact Information Card
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
                                    .shadow(color: primaryColor.opacity(0.3), radius: 5, x: 0, y: 3)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(labTech.fullName)
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

                        // Personal Information Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Personal Information")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(primaryColor)
                                .padding(.horizontal, 16)

                            ProfileRow2(title: "Name", value: labTech.fullName, icon: "person.fill")
                            ProfileRow2(title: "Phone Number", value: labTech.phoneNumber, icon: "phone.fill")
                            ProfileRow2(title: "Email", value: labTech.email, icon: "envelope.fill")
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

                        // Account Details Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Account Details")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(primaryColor)
                                .padding(.horizontal, 16)

                            ProfileRow2(title: "Technician ID", value: labTech.id, icon: "person.text.rectangle.fill")
                            ProfileRow2(title: "Department", value: labTech.department, icon: "building.fill")
                            ProfileRow2(title: "Join Date", value: "26/4/2025", icon: "calendar")
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
                                isLoggingOut = true
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
                    } else if let error = viewModel.error {
                        ErrorView1(error: error) {
                            viewModel.fetchLabTech(byId: labTechId)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if !isLoggingOut {
                viewModel.fetchLabTech(byId: labTechId)
            }
        }
        .fullScreenCover(isPresented: $showLoginView) {
            LoginView()
        }
    }
}

// Error View extracted for reusability
struct ErrorView1: View {
    let error: Error
    let retryAction: () -> Void
    let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 4) {
                Text("Error loading profile")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)

                Text(error.localizedDescription)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            Button(action: retryAction) {
                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
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
                    .shadow(color: primaryColor.opacity(0.3), radius: 5, x: 0, y: 3)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// ProfileRow for consistent styling
struct ProfileRow2: View {
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
