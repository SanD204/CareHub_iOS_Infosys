import Foundation
import Firebase
import FirebaseFirestore

class FirebaseManager {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func fetchPatientByPatientId(_ patientId: String, completion: @escaping (PatientInfo?, Error?) -> Void) {
        print("Fetching patient with patientId: \(patientId)")
        
        db.collection("patients")
            .whereField("patientId", isEqualTo: patientId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching patient: \(error.localizedDescription)")
                    completion(nil, error)
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("No patient found with patientId: \(patientId)")
                    completion(nil, nil)
                    return
                }
                
                print("Raw document data: \(document.data())")
                do {
                    let patient = try document.data(as: PatientInfo.self)
                    print("Fetched patient - ID: \(patient.patientId), Name: \(patient.name), Age: \(patient.age)")
                    completion(patient, nil)
                } catch {
                    print("Error decoding patient: \(error)")
                    completion(nil, error)
                }
            }
    }

    func fetchTestResults(forPatientId patientId: String, completion: @escaping ([TestResult]?, Error?) -> Void) {
        let collection = db.collection("medicalTests")
        
        print("Fetching test results for patientId: \(patientId)")
        
        if patientId.isEmpty {
            collection.getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching all test results: \(error.localizedDescription)")
                    completion(nil, error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No test result documents found")
                    completion([], nil)
                    return
                }
                
                let testResults = documents.compactMap { document -> TestResult? in
                    do {
                        let result = try document.data(as: TestResult.self)
                        return result
                    } catch {
                        print("Error decoding test result \(document.documentID): \(error)")
                        return nil
                    }
                }
                print("Fetched \(testResults.count) test results: \(testResults.map { $0.id })")
                completion(testResults, nil)
            }
        } else {
            collection.whereField("patientId", isEqualTo: patientId).getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching test results for patient \(patientId): \(error.localizedDescription)")
                    completion(nil, error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No test results found for patientId: \(patientId)")
                    completion([], nil)
                    return
                }
                
                let testResults = documents.compactMap { document -> TestResult? in
                    do {
                        let result = try document.data(as: TestResult.self)
                        return result
                    } catch {
                        print("Error decoding test result \(document.documentID): \(error)")
                        return nil
                    }
                }
                print("Fetched \(testResults.count) test results for patientId \(patientId): \(testResults.map { $0.id })")
                completion(testResults, nil)
            }
        }
    }

    func fetchPendingTests(completion: @escaping ([MedicalTest]?, Error?) -> Void) {
        print("Fetching pending medical tests")
        
        db.collection("medicalTests")
            .whereField("status", isEqualTo: "Pending")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching pending tests: \(error.localizedDescription)")
                    completion(nil, error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No pending test documents found")
                    completion([], nil)
                    return
                }
                
                let medicalTests = documents.compactMap { document -> MedicalTest? in
                    var data = document.data()
                    data["documentId"] = document.documentID // Include the Firestore document ID
                    do {
                        let test = try document.data(as: MedicalTest.self)
                        return test
                    } catch {
                        print("Error decoding medical test \(document.documentID): \(error)")
                        return nil
                    }
                }
                print("Fetched \(medicalTests.count) pending tests")
                completion(medicalTests, nil)
            }
    }
}

