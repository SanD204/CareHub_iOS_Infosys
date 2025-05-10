//
//  LabTechViewModel.swift
//  Carehub
//
//  Created by Dev on 08/05/25.
//

import Foundation
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
