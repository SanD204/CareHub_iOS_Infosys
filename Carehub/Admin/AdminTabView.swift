import SwiftUI
import os.log
struct AdminTabView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var staffManager = StaffManager()
    @State private var selectedTab = 0
    @State private var showLogoutAlert = false
    private let logger = Logger(subsystem: "com.yourapp.Carehub", category: "AdminTab")
    private let purpleColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    private let gradientColors = [Color(red: 0.43, green: 0.34, blue: 0.99), Color(red: 0.55, green: 0.48, blue: 0.99)]
    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.94, blue: 1.0)
                .edgesIgnoringSafeArea(.all)
            
            if authManager.isLoading {
                ProgressView("Loading admin data...")
                    .tint(purpleColor)
                    .onAppear {
                        logger.debug("Loading admin data...")
                    }
            } else if let admin = authManager.currentStaffMember, admin.role == .admin {
                mainTabView(admin: admin)
            }
        }
    }
    
    @ViewBuilder
    private func mainTabView(admin: Staff) -> some View {
        TabView(selection: $selectedTab) {
            AdminDashboardView(staffManager: staffManager)
                .tabItem {
                    Image(systemName: "house.fill")
                        .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                    Text("Dashboard")
                }
                .tag(0)
            
            StaffListView(staffManager: staffManager)
                .tabItem {
                    Image(systemName: "person.3.fill")
                        .environment(\.symbolVariants, selectedTab == 1 ? .fill : .none)
                    Text("Staff")
                }
                .tag(1)
            
            AnalyticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                        .environment(\.symbolVariants, selectedTab == 2 ? .fill : .none)
                    Text("Analytics")
                }
                .tag(2)
            
            AdminProfileView(admin: admin)
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                        .environment(\.symbolVariants, selectedTab == 3 ? .fill : .none)
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(purpleColor)
        .navigationBarBackButtonHidden(true)
    }
}
