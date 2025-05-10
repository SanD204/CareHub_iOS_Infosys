//
//  NurseHomeViewModel.swift
//  Carehub
//
//  Created by Dev on 08/05/25.
//

import Firebase
import Foundation

class NurseHomeViewModel: ObservableObject {
    @Published var allAppointments: [Appointment] = []
    @Published var filteredAppointments: [Appointment] = []
    @Published var searchText: String = ""
    
    init() {
        fetchAppointments()
    }

    func fetchAppointments() {
        FirebaseService.shared.fetchAppointmentsForToday { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let appointments):
                    // Filter out cancelled appointments
                    let activeAppointments = appointments.filter { $0.status.lowercased() != "cancelled" }
                    self.allAppointments = activeAppointments
                    self.filterAppointments()
                case .failure(let error):
                    print("Error fetching appointments: \(error)")
                }
            }
        }
    }

    func filterAppointments() {
        if searchText.isEmpty {
            filteredAppointments = allAppointments
        } else {
            let lowercased = searchText.lowercased()
            
            // We'll filter in two steps:
            // 1. First filter by IDs that might match (fast)
            let potentiallyMatching = allAppointments.filter { appt in
                appt.patientId.lowercased().contains(lowercased) ||
                appt.docId.lowercased().contains(lowercased)
            }
            
            // 2. Then check names for these filtered appointments
            filterAppointmentsByName(potentiallyMatching, searchTerm: lowercased)
        }
    }
    
    private func filterAppointmentsByName(_ appointments: [Appointment], searchTerm: String) {
        var matchingAppointments: [Appointment] = []
        let group = DispatchGroup()
        
        for appt in appointments {
            group.enter()
            
            // Check both patient and doctor names
            var patientMatches = false
            var doctorMatches = false
            
            // Check patient name
            FirebaseService.shared.fetchPatientName(patientID: appt.patientId) { result in
                if case .success(let name) = result, name.lowercased().contains(searchTerm) {
                    patientMatches = true
                }
                
                // Check doctor name
                FirebaseService.shared.fetchDoctorName(docId: appt.docId) { result in
                    if case .success(let name) = result, name.lowercased().contains(searchTerm) {
                        doctorMatches = true
                    }
                    
                    if patientMatches || doctorMatches {
                        DispatchQueue.main.async {
                            matchingAppointments.append(appt)
                        }
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            self.filteredAppointments = matchingAppointments
        }
    }
    
    func getPatientName(for patientId: String, completion: @escaping (String) -> Void) {
            FirebaseService.shared.fetchPatientName(patientID: patientId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let name):
                        completion(name)
                    case .failure(_):
                        completion("Unknown Patient")
                    }
                }
            }
        }
        
        func getDoctorName(for docId: String, completion: @escaping (String) -> Void) {
            FirebaseService.shared.fetchDoctorName(docId: docId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let name):
                        completion(name)
                    case .failure(_):
                        completion("Unknown Doctor")
                    }
                }
            }
        }
}
