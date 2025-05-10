import FirebaseFirestore
import SwiftUI

class AppointmentViewModel: ObservableObject {
    private var db = Firestore.firestore()
    
    @Published var recentPrescriptions: [Appointment] = []
    @Published var medicalTests: [TestResult] = []
    @Published var errorMessage: String?
    
    func fetchRecentPrescriptions(forPatientId patientId: String) {
        print("Fetching prescriptions for patient ID: \(patientId)")
            self.db.collection("appointments")
                .whereField("patientId", isEqualTo: patientId)
                .getDocuments { (querySnapshot, error) in
                    if let error = error {
                        self.errorMessage = "Error fetching data: \(error.localizedDescription)"
                        print("Error fetching documents: \(error.localizedDescription)")
                        return
                    }
                    
                    print("Fetched documents: \(querySnapshot?.documents.count ?? 0)")
                    
                    let today = Calendar.current.startOfDay(for: Date())
                    
                    self.recentPrescriptions = querySnapshot?.documents.compactMap { document in
                        print("Processing document with ID: \(document.documentID)")
                        if let apptId = document.data()["apptId"] as? String,
                           let patientId = document.data()["patientId"] as? String,
                           let description = document.data()["description"] as? String,
                           let docId = document.data()["docId"] as? String,
                           let status = document.data()["status"] as? String,
                           let billingStatus = document.data()["billingStatus"] as? String,
                           let amount = document.data()["amount"] as? Double,
                           let dateTimestamp = document.data()["date"] as? Timestamp,
                           let doctorsNotes = document.data()["doctorsNotes"] as? String,
                           let prescriptionId = document.data()["prescriptionId"] as? String,
                           let followUpRequired = document.data()["followUpRequired"] as? Bool,
                           let followUpDateTimestamp = document.data()["followUpDate"] as? Timestamp {
                            
                            let date = dateTimestamp.dateValue()
                            let followUpDate = followUpDateTimestamp.dateValue()
                            
                            let appointment = Appointment(
                                id: apptId,
                                apptId: apptId,
                                patientId: patientId,
                                description: description,
                                docId: docId,
                                status: status,
                                billingStatus: billingStatus,
                                amount: amount,
                                date: date,
                                doctorsNotes: doctorsNotes,
                                prescriptionId: prescriptionId,
                                followUpRequired: followUpRequired,
                                followUpDate: followUpDate
                            )
                            
                            print("Successfully decoded appointment with ID: \(appointment.apptId)")
                            return appointment
                        } else {
                            print("Failed to decode appointment for document ID: \(document.documentID)")
                            return nil
                        }
                    }.filter { appointment in
                        guard let date = appointment.date,
                              let prescriptionId = appointment.prescriptionId else {
                            return false
                        }
                        return date < today && !prescriptionId.isEmpty
                    } ?? []
                    
                    print("Total prescriptions after filtering: \(self.recentPrescriptions.count)")
                    print("PRESCRIPTIONS: \(self.recentPrescriptions)")
                }
    }
    
    func fetchMedicalTests(forPatientId patientId: String) async {
        let today = Calendar.current.startOfDay(for: Date())

        do {
            let snapshot = try await db.collection("medicalTests")
                .whereField("patientId", isEqualTo: patientId)
                .getDocuments()

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")

            var filteredTests: [TestResult] = []

            for document in snapshot.documents {
                do {
                    let testResult = try document.data(as: TestResult.self)

                    guard !testResult.pdfUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        print("⛔️ Skipped test ID \(testResult.id) - empty pdfUrl")
                        continue
                    }

                    guard let testDate = dateFormatter.date(from: testResult.date) else {
                        print("⛔️ Skipped test ID \(testResult.id) - invalid date format: \(testResult.date)")
                        continue
                    }

                    if testDate < today {
                        filteredTests.append(testResult)
                    } else {
                        print("⛔️ Skipped test ID \(testResult.id) - future date: \(testResult.date)")
                    }

                } catch {
                    print("❌ Failed to decode test document \(document.documentID): \(error.localizedDescription)")
                }
            }

            // ✅ Ensure UI update happens on the main thread
            DispatchQueue.main.async {
                self.medicalTests = filteredTests
                print("✅ Total valid medical tests: \(self.medicalTests.count)")
            }

        } catch {
            print("❌ Error fetching medical tests: \(error.localizedDescription)")
        }
    }


}
