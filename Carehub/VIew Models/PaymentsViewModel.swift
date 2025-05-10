//
//  PaymentsViewModel.swift
//  Carehub
//
//  Created by Dev on 08/05/25.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

class PaymentsViewModel: ObservableObject {
    @Published var payments: [Billing] = []
    @Published var error: Error?
    @Published var isLoading = false
    @Published var patientNames: [String: String] = [:]
    @Published var doctorNames: [String: String] = [:]
    
    private let db = Firestore.firestore()
    
    func getBills() {
        isLoading = true
        error = nil
        
        db.collection("payments")
            .order(by: "date", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                defer {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.error = error
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let fetchedBills: [Billing] = documents.compactMap { doc in
                    let data = doc.data()
                    let billingId = data["billingId"] as? String ?? doc.documentID
                    let appointmentId = data["appointmentId"] as? String ?? ""
                    let billingStatus = data["billingStatus"] as? String ?? ""
                    let doctorId = data["doctorId"] as? String ?? ""
                    let patientId = data["patientId"] as? String ?? ""
                    let paymentMode = data["paymentMode"] as? String ?? ""
                    let insuranceAmt = data["insuranceAmt"] as? Double ?? 0.0
                    let paidAmt = data["paidAmt"] as? Double ?? 0.0
                    let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
                    let billURL = data["billURL"] as? String ?? ""
                    
                    let billItems: [BillItem]
                    if let items = data["bills"] as? [[String: Any]] {
                        billItems = items.compactMap { item in
                            guard let itemName = item["itemName"] as? String,
                                  let fee = item["fee"] as? Double,
                                  let isPaid = item["isPaid"] as? Bool else {
                                return nil
                            }
                            return BillItem(fee: fee, isPaid: isPaid, itemName: itemName)
                        }
                    } else {
                        billItems = []
                    }
                    
                    return Billing(
                        billingId: billingId,
                        bills: billItems,
                        appointmentId: appointmentId,
                        billingStatus: billingStatus,
                        date: date,
                        doctorId: doctorId,
                        insuranceAmt: insuranceAmt,
                        paidAmt: paidAmt,
                        patientId: patientId,
                        paymentMode: paymentMode,
                        billURL: billURL
                    )
                }
                
                DispatchQueue.main.async {
                    self.payments = fetchedBills
                    self.fetchPatientAndDoctorNames(from: fetchedBills)
                }
            }
    }
    
    func fetchPatientAndDoctorNames(from bills: [Billing]) {
        let patientIDs = Set(bills.map { $0.patientId })
        let doctorIDs = Set(bills.map { $0.doctorId })
        
        // Fetch patient names
        for patientId in patientIDs where !patientId.isEmpty {
            db.collection("patients").document(patientId).getDocument { [weak self] snapshot, error in
                guard let self = self, let data = snapshot?.data() else { return }
                
                let name = (data["userData"] as? [String: Any])?["Name"] as? String ?? ""
                
                DispatchQueue.main.async {
                    self.patientNames[patientId] = name.isEmpty ? "Unknown Patient" : name
                }
            }
        }
        
        // Fetch doctor names
        for doctorId in doctorIDs where !doctorId.isEmpty {
            db.collection("doctors").document(doctorId).getDocument { [weak self] snapshot, error in
                guard let self = self, let data = snapshot?.data() else { return }
                
                let name = data["Doctor_name"] as? String ?? ""
                let specialty = data["Department"] as? String ?? ""
                let displayName = name.isEmpty ? "Unknown Doctor" : "Dr. \(name)" + (specialty.isEmpty ? "" : " (\(specialty))")
                
                DispatchQueue.main.async {
                    self.doctorNames[doctorId] = displayName
                }
            }
        }
    }
}
