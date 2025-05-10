//
//  LabTechTabView.swift
//  Carehub
//
//  Created by admin24 on 21/04/25.
//

import SwiftUI

struct LabTechTabView: View {
    var body: some View {
        TabView {
            HomeView_LT()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            Records_LT()
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                    Text("Records")
                }
            
            ProfileView_LT(labTechId: "WFQ7R40YZICIGLXRJDYOHDXDLKD3")
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Set tab bar appearance
            let tabBarAppearance = UITabBarAppearance()
            
            // Configure normal state
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.gray
            ]
            
            // Configure selected state with your custom color
            let selectedColor = UIColor(red: 0.43, green: 0.34, blue: 0.99, alpha: 1.0)
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = selectedColor
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: selectedColor
            ]
            
            // Apply the appearance
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}
