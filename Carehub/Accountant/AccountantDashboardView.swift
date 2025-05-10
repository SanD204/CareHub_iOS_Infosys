import SwiftUI

struct AccountantDashboard: View {
    @State private var selectedTab = 0
    @StateObject private var viewModel = AccountantViewModel()
    let primaryColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    let accountantId: String
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                ZStack {

                    LinearGradient(
                        colors: [
                            Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.1),
                            Color(red: 0.94, green: 0.94, blue: 1.0).opacity(0.9),
                            Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .edgesIgnoringSafeArea(.all)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                if viewModel.isLoading {
                                    Text("Loading...")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(primaryColor)
                                } else if let accountant = viewModel.accountant {
                                    Text("Hi, \(accountant.name)")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                    Text("Receptionist")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                } else {
                                    Text("Welcome")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(primaryColor)
                                    Text("Receptionist")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            
                            // Accountant Cards Grid
                            VStack(spacing: 16) {
                                NavigationLink(destination: GenerateBillView()) {
                                    AccountantCard(
                                        title: "Generate Bill",
                                        icon: "doc.text",
                                        color: primaryColor
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 24)
                                }
                                .tint(primaryColor) // Sets back button to purple for GenerateBillView
                                
                                NavigationLink(destination: PaymentHistoryView()) {
                                    AccountantCard(
                                        title: "Payment History",
                                        icon: "chart.bar.fill",
                                        color: primaryColor
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 24)
                                }
                            }
                            .padding(.top)
                        }
                    }
                }
                .navigationBarHidden(true)
                .tint(primaryColor) // Sets navigation tint to purple
                .onAppear {
                    viewModel.fetchAccountant(byAccountantId: accountantId)
                }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            AccountantProfileView(accountantId: accountantId)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(1)
        }
        .tint(primaryColor) // Sets selected tab bar item color to purple
        .environment(\.colorScheme, .light) // Force light mode for consistent colors
    }
}

struct AccountantCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .padding(12)
                .background(color.opacity(0.1))
                .clipShape(Circle())
                .frame(width: 44, height: 44)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.black) // Explicit color for light mode
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(Color(red: 0.98, green: 0.98, blue: 0.98)) // Light gray background for card
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    Group {
        AccountantDashboard(accountantId: "KV93GmJ9k9VtzHtx0M8p1fH30Mf2")
            .preferredColorScheme(.light)
    }
}
