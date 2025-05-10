//import SwiftUI
//import FirebaseFirestore
//
//struct NotesView: View {
//    let appointment: Appointment
//    @State private var notes: String = ""
//    @State private var showAlert: Bool = false
//    @State private var alertMessage: String = ""
//    @State private var navigateBackToPatientProfile = false
//    
//    private let db = Firestore.firestore()
//    private let purpleColor = Color(red: 0.43, green: 0.34, blue: 0.99)
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 16) {
//                // Header
//                Text("Add Notes for Appointment")
//                    .font(.system(.title2, design: .rounded, weight: .bold))
//                    .foregroundColor(.primary)
//                    .padding(.top, 16)
//                
//                // Text Editor
//                TextEditor(text: $notes)
//                    .font(.system(.body, design: .rounded))
//                    .frame(minHeight: 200)
//                    .padding(8)
//                    .background(Color(.systemGray6))
//                    .cornerRadius(8)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 8)
//                            .stroke(purpleColor, lineWidth: 1)
//                    )
//                
//                // Buttons
//                HStack(spacing: 16) {
//                    Button(action: {
//                        print("Cancel button tapped, navigating back to PatientProfileView")
//                        navigateBackToPatientProfile = true
//                    }) {
//                        Text("Cancel")
//                            .font(.system(.body, design: .rounded, weight: .medium))
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.gray.opacity(0.2))
//                            .foregroundColor(.primary)
//                            .cornerRadius(8)
//                    }
//                    
//                    Button(action: {
//                        saveNotes()
//                    }) {
//                        Text("Save")
//                            .font(.system(.body, design: .rounded, weight: .medium))
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(purpleColor)
//                            .foregroundColor(.white)
//                            .cornerRadius(8)
//                    }
//                }
//                
//                Spacer()
//            }
//            .padding(.horizontal)
//            .navigationTitle("Notes")
//            .navigationBarTitleDisplayMode(.inline)
//            .navigationBarBackButtonHidden(true) // Hide default back button
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button(action: {
//                        print("Custom back button tapped, navigating back to PatientProfileView")
//                        navigateBackToPatientProfile = true
//                    }) {
//                        Image(systemName: "chevron.left")
//                            .foregroundColor(purpleColor)
//                        Text("Back")
//                            .foregroundColor(purpleColor)
//                    }
//                }
//            }
//            .navigationDestination(isPresented: $navigateBackToPatientProfile) {
//                PatientProfileView(
//                    patientIdentifier: appointment.patientId,
//                    doctorId: appointment.docId,
//                    doctorName: "Doctor" // Ideally, fetch this from AuthManager or pass from DoctorDashboardView
//                )
//            }
//            .alert(isPresented: $showAlert) {
//                Alert(
//                    title: Text("Notes"),
//                    message: Text(alertMessage),
//                    dismissButton: .default(Text("OK")) {
//                        if alertMessage.contains("successfully") {
//                            print("Notes saved successfully, navigating back to PatientProfileView")
//                            navigateBackToPatientProfile = true
//                        }
//                    }
//                )
//            }
//            .onAppear {
//                print("NotesView appeared, fetching notes for apptId: \(appointment.apptId)")
//                fetchNotes()
//            }
//            .onDisappear {
//                print("NotesView disappeared")
//            }
//        }
//    }
//    
//    private func fetchNotes() {
//        guard !appointment.apptId.isEmpty, !appointment.docId.isEmpty else {
//            print("Skipping fetchNotes: apptId or docId is empty")
//            notes = appointment.doctorsNotes ?? ""
//            return
//        }
//        
//        db.collection("doctors")
//            .document(appointment.docId)
//            .collection("doctorsNotes")
//            .document(appointment.apptId)
//            .getDocument { document, error in
//                if let error = error {
//                    alertMessage = "Error fetching notes: \(error.localizedDescription)"
//                    showAlert = true
//                    return
//                }
//                
//                if let document = document, document.exists {
//                    notes = document.get("note") as? String ?? ""
//                    print("Fetched notes: \(notes)")
//                } else {
//                    notes = appointment.doctorsNotes ?? ""
//                    print("No notes found in Firestore, using appointment.doctorsNotes: \(notes)")
//                }
//            }
//    }
//    
//    private func saveNotes() {
//        guard !notes.trimmingCharacters(in: .whitespaces).isEmpty else {
//            alertMessage = "Please enter some notes before saving."
//            showAlert = true
//            return
//        }
//        
//        let notesData: [String: Any] = [
//            "appointmentID": appointment.apptId,
//            "note": notes,
//            "patientID": appointment.patientId
//        ]
//        
//        print("Saving notes to: doctors/\(appointment.docId)/doctorsNotes/\(appointment.apptId)")
//        db.collection("doctors")
//            .document(appointment.docId)
//            .collection("doctorsNotes")
//            .document(appointment.apptId)
//            .setData(notesData, merge: true) { error in
//                if let error = error {
//                    alertMessage = "Error saving notes: \(error.localizedDescription)"
//                    print("Error saving notes: \(error.localizedDescription)")
//                } else {
//                    alertMessage = "Notes saved successfully"
//                    db.collection("appointments")
//                        .document(appointment.id)
//                        .updateData(["doctorsNotes": notes]) { updateError in
//                            if let updateError = updateError {
//                                print("Error updating appointments collection: \(updateError.localizedDescription)")
//                            }
//                        }
//                    print("Notes saved successfully")
//                }
//                showAlert = true
//            }
//    }
//}

import SwiftUI
import FirebaseFirestore

struct NotesView: View {
    let appointment: Appointment
    @State private var notes: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var navigateBackToPatientProfile = false
    
    private let db = Firestore.firestore()
    private let purpleColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Header
                Text("Add Notes for Appointment")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.top, 16)
                
                // Text Editor
                TextEditor(text: $notes)
                    .font(.system(.body, design: .rounded))
                    .frame(minHeight: 200)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(purpleColor, lineWidth: 1)
                    )
                
                // Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        print("Cancel button tapped, navigating back to PatientProfileView")
                        navigateBackToPatientProfile = true
                    }) {
                        Text("Cancel")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        saveNotes()
                    }) {
                        Text("Save")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(purpleColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true) // Hide default back button
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        print("Custom back button tapped, navigating back to PatientProfileView")
                        navigateBackToPatientProfile = true
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(purpleColor)
                        Text("Back")
                            .foregroundColor(purpleColor)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateBackToPatientProfile) {
                PatientProfileView(
                    patientIdentifier: appointment.patientId,
                    doctorId: appointment.docId,
                    doctorName: "Doctor", // Ideally, fetch this from AuthManager or pass from DoctorDashboardView
                    apptId: appointment.apptId // Pass the apptId
                )
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Notes"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertMessage.contains("successfully") {
                            print("Notes saved successfully, navigating back to PatientProfileView")
                            navigateBackToPatientProfile = true
                        }
                    }
                )
            }
            .onAppear {
                print("NotesView appeared, fetching notes for apptId: \(appointment.apptId)")
                fetchNotes()
            }
            .onDisappear {
                print("NotesView disappeared")
            }
        }
    }
    
    private func fetchNotes() {
        guard !appointment.apptId.isEmpty, !appointment.docId.isEmpty else {
            print("Skipping fetchNotes: apptId or docId is empty")
            notes = appointment.doctorsNotes ?? ""
            return
        }
        
        db.collection("doctors")
            .document(appointment.docId)
            .collection("doctorsNotes")
            .document(appointment.apptId)
            .getDocument { document, error in
                if let error = error {
                    alertMessage = "Error fetching notes: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                if let document = document, document.exists {
                    notes = document.get("note") as? String ?? ""
                    print("Fetched notes: \(notes)")
                } else {
                    notes = appointment.doctorsNotes ?? ""
                    print("No notes found in Firestore, using appointment.doctorsNotes: \(notes)")
                }
            }
    }
    
    private func saveNotes() {
        guard !notes.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "Please enter some notes before saving."
            showAlert = true
            return
        }
        
        let notesData: [String: Any] = [
            "appointmentID": appointment.apptId,
            "note": notes,
            "patientID": appointment.patientId
        ]
        
        print("Saving notes to: doctors/\(appointment.docId)/doctorsNotes/\(appointment.apptId)")
        db.collection("doctors")
            .document(appointment.docId)
            .collection("doctorsNotes")
            .document(appointment.apptId)
            .setData(notesData, merge: true) { error in
                if let error = error {
                    alertMessage = "Error saving notes: \(error.localizedDescription)"
                    print("Error saving notes: \(error.localizedDescription)")
                } else {
                    alertMessage = "Notes saved successfully"
                    db.collection("appointments")
                        .document(appointment.id)
                        .updateData(["doctorsNotes": notes]) { updateError in
                            if let updateError = updateError {
                                print("Error updating appointments collection: \(updateError.localizedDescription)")
                            }
                        }
                    print("Notes saved successfully")
                }
                showAlert = true
            }
    }
}
