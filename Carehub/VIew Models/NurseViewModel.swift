//
//  NurseViewModel.swift
//  Carehub
//
//  Created by Dev on 08/05/25.
//
import Firebase
import Foundation
class NurseViewModel: ObservableObject {
    @Published var nurse: Nurse?
    @Published var isLoading = false
    @Published var error: Error?

    func fetchNurse(byNurseId nurseId: String) {
        isLoading = true
        error = nil

        FirebaseService.shared.fetchNurse(byId: nurseId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let nurse):
                    self.nurse = nurse
                case .failure(let err):
                    self.error = err
                }
            }
        }
    }
}
