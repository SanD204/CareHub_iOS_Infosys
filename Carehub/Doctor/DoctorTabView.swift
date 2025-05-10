import SwiftUI

struct DoctorTabView: View {
    @State private var selectedTab: Int = 0
    @State private var showChangePasswordCard: Bool = false
    @State private var oldPassword: String = ""
    @State private var newPassword: String = ""
    @State private var reEnterNewPassword: String = ""
    @State private var passwordErrorMessage: String?
    @State private var showConfirmPasswordChangeAlert: Bool = false
    @State private var showLogoutAlert: Bool = false
    @State private var logoutErrorMessage: String?
    @State private var isLoggedOut: Bool = false
    private let purpleColor = Color(hex: "6D57FC")

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home tab (DoctorDashboardView)
            DoctorDashboardView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(0)
                .navigationBarHidden(true) // Hide navigation bar for this tab
            
            // Patient tab (MyPatientsView)
            MyPatientsView()
                .tabItem {
                    Image(systemName: "cross.case")
                    Text("Patient")
                }
                .tag(1)
                .navigationBarHidden(true) // Hide navigation bar for this tab
            
            // Profile tab (ProfileView_doc)
            ProfileView_doc(
                showChangePasswordCard: $showChangePasswordCard,
                oldPassword: $oldPassword,
                newPassword: $newPassword,
                reEnterNewPassword: $reEnterNewPassword,
                passwordErrorMessage: $passwordErrorMessage,
                showConfirmPasswordChangeAlert: $showConfirmPasswordChangeAlert,
                showLogoutAlert: $showLogoutAlert,
                logoutErrorMessage: $logoutErrorMessage,
                isLoggedOut: $isLoggedOut
            )
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(2)
                .navigationBarHidden(true) // Hide navigation bar for this tab
        }
        .tint(Color(red: 0.43, green: 0.34, blue: 0.99)) // Updated color for selected tab
        .navigationBarHidden(true) // Ensure the tab view itself has no navigation bar
        .onAppear {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            
            // Selected tab color
            tabBarAppearance.selectionIndicatorTintColor = UIColor(red: 0.43, green: 0.34, blue: 0.99, alpha: 1.0) // Updated color
            
            // Unselected tab color
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
            
            // Apply appearance to both standard and scroll edge
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}

struct DoctorTabView_Previews: PreviewProvider {
    static var previews: some View {
        DoctorTabView()
    }
}
