import SwiftUI

struct NurseProfileView: View {
    let nurseId: String
    @StateObject private var viewModel = NurseViewModel()
    let primaryColor = Color(red: 109/255, green: 87/255, blue: 252/255)
    @State private var isEditingProfile = false
    @State private var showLogoutAlert = false
    @State private var logoutErrorMessage: String?
    @State private var isLoggedOut = false

    var body: some View {
        NavigationView {
            List {
                if viewModel.isLoading && !isLoggedOut { // Only show loading if not logged out
                    ProgressView("Loading profile...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowSeparator(.hidden)
                } else if let nurse = viewModel.nurse, !isLoggedOut {
                    // Profile Header
                    Section {
                        VStack(alignment: .center, spacing: 16) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(primaryColor)
                            
                            VStack(spacing: 4) {
                                Text(nurse.name)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text(nurse.nurseld)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.clear)
                    }
                    .listRowBackground(Color.clear)
                    
                    // Contact Info
                    Section(header: Text("Contact Information")) {
                        LabeledContent(label: "Phone", content: nurse.phoneNo ?? "N/A")
                        LabeledContent(label: "Email", content: nurse.email)
                    }
                    
                    // Shift Info
                    Section(header: Text("Shift Information")) {
                        LabeledContent(
                            label: "Start Time",
                            content: formattedTime(from: nurse.shift?.startTime)
                        )
                        LabeledContent(
                            label: "End Time",
                            content: formattedTime(from: nurse.shift?.endTime)
                        )
                    }
                    
                    // Logout Button
                    Section {
                        Button(action: {
                            authManager.logout()
                            if authManager.errorMessage == nil {
                                isLoggedOut = true
                                viewModel.nurse = nil
                                viewModel.error = nil
                                viewModel.isLoading = false
                                print("Logout successful, presenting LoginView")
                            } else {
                                showLogoutAlert = true
                                logoutErrorMessage = authManager.errorMessage
                                print("Logout failed: \(authManager.errorMessage ?? "Unknown error")")
                            }
                        }) {
                            Text("Logout")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .alert(isPresented: $showLogoutAlert) {
                Alert(
                    title: Text("Logout Failed"),
                    message: Text(logoutErrorMessage ?? "An error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
//                if !isLoggedOut { // Only fetch if not logged out
                    viewModel.fetchNurse(byNurseId: nurseId)
//                }
            }
            .fullScreenCover(isPresented: $isLoggedOut) {
                LoginView()
            }
            
        }
    }

    private var authManager: AuthManager {
        AuthManager.shared
    }

    private func formattedTime(from date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    NurseProfileView(nurseId: "xg318OgdXaZSY4M3HSlnBsvajeY2")
}
