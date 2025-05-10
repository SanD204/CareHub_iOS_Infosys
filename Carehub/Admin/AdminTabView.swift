import SwiftUI
import os.log

struct AdminTabView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var staffManager = StaffManager()
    @State private var selectedTab = 0
    @State private var showLogoutAlert = false
    private let logger = Logger(subsystem: "com.yourapp.Carehub", category: "AdminTab")
    private let purpleColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    private let gradientColors = [
        Color(red: 0.43, green: 0.34, blue: 0.99),
        Color(red: 0.55, green: 0.48, blue: 0.99)
    ]
    private let tabBarBackgroundColor = Color(red: 0.94, green: 0.94, blue: 1.0)
    private let unselectedItemColor = Color.gray

    init() {
        // Customize tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(tabBarBackgroundColor)
        
        // Set selected and unselected item colors
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(unselectedItemColor)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(unselectedItemColor)]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(purpleColor)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(purpleColor)]
        
        // Apply appearance to standard and scroll edge
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            if authManager.isLoading {
                ProgressView("Loading admin data...")
                    .tint(purpleColor)
                    .foregroundColor(.black)
                    .onAppear {
                        logger.debug("Loading admin data...")
                    }
            } else if let admin = authManager.currentStaffMember, admin.role == .admin {
                mainTabView(admin: admin)
            }
        }
        .environment(\.colorScheme, .light) // Enforce light mode
    }
    
    @ViewBuilder
    private func mainTabView(admin: Staff) -> some View {
        TabView(selection: $selectedTab) {
            AdminDashboardView(staffManager: staffManager)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        .foregroundColor(selectedTab == 0 ? purpleColor : unselectedItemColor)
                    Text("Dashboard")
                        .foregroundColor(selectedTab == 0 ? purpleColor : unselectedItemColor)
                }
                .tag(0)
            
            StaffListView(staffManager: staffManager)
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "person.3.fill" : "person.3")
                        .foregroundColor(selectedTab == 1 ? purpleColor : unselectedItemColor)
                    Text("Staff")
                        .foregroundColor(selectedTab == 1 ? purpleColor : unselectedItemColor)
                }
                .tag(1)
            
            AnalyticsView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
                        .foregroundColor(selectedTab == 2 ? purpleColor : unselectedItemColor)
                    Text("Analytics")
                        .foregroundColor(selectedTab == 2 ? purpleColor : unselectedItemColor)
                }
                .tag(2)
            
            AdminProfileView(admin: admin)
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.crop.circle.fill" : "person.crop.circle")
                        .foregroundColor(selectedTab == 3 ? purpleColor : unselectedItemColor)
                    Text("Profile")
                        .foregroundColor(selectedTab == 3 ? purpleColor : unselectedItemColor)
                }
                .tag(3)
        }
        .navigationBarBackButtonHidden(true)
    }
}
