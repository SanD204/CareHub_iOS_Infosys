import SwiftUI

struct NurseTabView: View {
    var nurseId: String
    var body: some View {
        TabView {
            NurseHomeView(nurseId: nurseId)
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            NurseProfileView(nurseId: nurseId)
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
        .tint(Color(red: 0.43, green: 0.34, blue: 0.99)) // Updated color for selected tab
        .navigationBarBackButtonHidden(true)
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
