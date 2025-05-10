import SwiftUI

struct Appointment: Identifiable, Decodable {
    var id: String
    let apptId: String
    let patientId: String
    let description: String
    let docId: String
    var status: String
    let billingStatus: String
    let amount: Double?
    var date: Date?
    let doctorsNotes: String?
    var prescriptionId: String?
    let followUpRequired: Bool?
    var followUpDate: Date?
    enum CodingKeys: String, CodingKey {
            case id
            case apptId
            case patientId
            case description
            case docId
            case status
            case billingStatus
            case amount
            case date
            case doctorsNotes
            case prescriptionId
            case followUpRequired
            case followUpDate
        }
}
