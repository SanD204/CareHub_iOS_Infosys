import SwiftUI

struct PatientTabView: View {
    let username: String
    let patient: PatientF
    
    init(username: String, patient: PatientF) {
        self.username = username
        self.patient = patient
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.selectionIndicatorTintColor = UIColor(red: 0.43, green: 0.34, blue: 0.99, alpha: 1.0)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    var body: some View {
        TabView {
            HomeView_patient(patient: patient)
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            DoctorView(patientId: patient.patientId)
                .tabItem {
                    Image(systemName: "stethoscope")
                    Text("Doctor")
                }
            
            SettingsView_patient(patient: patient)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
        .navigationBarBackButtonHidden(true)
        .accentColor(Color(red: 0.43, green: 0.34, blue: 0.99))
    }
}
