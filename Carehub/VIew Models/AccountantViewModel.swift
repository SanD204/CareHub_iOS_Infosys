//
//  AccountantViewModel.swift
//  Carehub
//
//  Created by Dev on 08/05/25.
//
import Foundation
import FirebaseFirestore
import FirebaseStorage

class AccountantViewModel: ObservableObject {
    @Published var accountant: Accountant?
    @Published var isLoading = false
    @Published var error: Error?

    private let accountantService = FirebaseAccountantService()
    
    func fetchAccountant(byAccountantId accountantId: String) {
        isLoading = true
        error = nil
        
        accountantService.fetchAccountant(byAccountantId: accountantId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let accountant):
                    self?.accountant = accountant
                case .failure(let err):
                    self?.error = err
                    print("Error fetching accountant: \(err.localizedDescription)")
                }
            }
        }
    }
    
//    func updateShiftHours(accountantId: String, newStart: String, newEnd: String) {
//        accountantService.updateShiftHours(accountantId: accountantId, newStart: newStart, newEnd: newEnd) { [weak self] error in
//            if let error = error {
//                print("Error updating shift: \(error.localizedDescription)")
//            } else {
//                print("Shift updated successfully")
//                self?.fetchAccountant(byAccountantId: accountantId)
//            }
//        }
//    }
}
