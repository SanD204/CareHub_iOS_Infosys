import SwiftUI

struct AccountantProfileView: View {
    let accountantId: String
    @StateObject private var viewModel = AccountantViewModel()
    let primaryColor = Color(red: 109/255, green: 87/255, blue: 252/255)
    @State private var isEditingProfile = false
    @State private var isLoggingOut = false
    @State private var showLoginView = false
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.isLoading {
                    ProgressView("Loading profile...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowSeparator(.hidden)
                } else if let accountant = viewModel.accountant {
                    // Profile Header Section
                    Section {
                        VStack(alignment: .center, spacing: 16) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(primaryColor)
                                .symbolRenderingMode(.hierarchical)
                            
                            VStack(spacing: 4) {
                                Text(accountant.name)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text(accountant.accountantId)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color(.systemGroupedBackground))
                    
                    // Contact Information Section
                    Section(header: Text("Contact Information")) {
                        LabeledContent(label: "Phone", content: accountant.phoneNo)
                        LabeledContent(label: "Email", content: accountant.email)
                    }
                    
                    Section(header: Text("Shift Information")) {
                        if let start = accountant.shift?.startTime, let end = accountant.shift?.endTime {
                            LabeledContent(
                                label: "Start Time",
                                content: DateFormatter.localizedString(from: start, dateStyle: .none, timeStyle: .short)
                            )
                            LabeledContent(
                                label: "End Time",
                                content: DateFormatter.localizedString(from: end, dateStyle: .none, timeStyle: .short)
                            )
                        } else {
                            Text("No shift assigned")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Logout Section
                    Section {
                        if isLoggingOut {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Button("Logout") {
                                isLoggingOut = true
                                // Perform logout and reset AuthManager states
                                AuthManager.shared.logout()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isLoggingOut = false
                                    showLoginView = true
                                }
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.fetchAccountant(byAccountantId: accountantId)
            }
            .fullScreenCover(isPresented: $showLoginView) {
                LoginView()
            }
        }
        .onAppear {
            viewModel.fetchAccountant(byAccountantId: accountantId)
        }
    }
}

#Preview {
    AccountantProfileView(accountantId: "ACC91219")
}
