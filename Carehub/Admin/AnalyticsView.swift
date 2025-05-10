import SwiftUI
import FirebaseFirestore
import Charts

// MARK: - Data Models
struct DailyAppointmentData: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

struct WeeklyAppointmentData: Identifiable {
    let id = UUID()
    let weekStart: Date
    let count: Int
}

struct MonthlyAppointmentData: Identifiable {
    let id = UUID()
    let monthStart: Date
    let count: Int
}

// MARK: - Main View
struct AnalyticsView: View {
    @StateObject private var analyticsManager = AnalyticsManager()
    private let purpleColor = Color(hex: "6D57FC")
    private let backgroundColor = Color(hex: "F6F7FF")

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .edgesIgnoringSafeArea(.all)
                
                if analyticsManager.isLoading {
                    ProgressView("Loading analytics...")
                } else {
                    VStack(spacing: 12) {
                        Text("Analytics")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.top, 2)
                            .padding(.bottom, 4) // Adjusted to increase spacing below title
                        
                        // Analytics Cards
                        VStack(spacing: 12) {
                            AnalyticsCard(
                                title1: "Appointments",
                                value1: "\(analyticsManager.totalAppointments)",
                                icon1: "calendar",
                                title2: "Cancellation Rate",
                                value2: String(format: "%.1f%%", analyticsManager.cancellationRate),
                                icon2: "xmark.circle"
                            )
                            
                            AnalyticsCard(
                                title1: "Total Revenue",
                                value1: "₹\(String(format: "%.2f", analyticsManager.totalRevenue))",
                                icon1: "indianrupeesign.circle",
                                title2: "Avg Revenue",
                                value2: "₹\(String(format: "%.2f", analyticsManager.averageRevenuePerAppointment))",
                                icon2: "chart.bar"
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            
                            CombinedAppointmentsChart(
                                dailyAppointments: analyticsManager.dailyAppointments,
                                weeklyAppointments: analyticsManager.weeklyAppointments,
                                monthlyAppointments: analyticsManager.monthlyAppointments
                            )
                            .padding()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    }
                }
            }
            .onAppear {
                analyticsManager.fetchAnalytics()
            }
        }
    }
}

// MARK: - Analytics Card
struct AnalyticsCard: View {
    let title1: String
    let value1: String
    let icon1: String
    let title2: String
    let value2: String
    let icon2: String
    private let purpleColor = Color(hex: "6D57FC")
    @State private var isTapped = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .shadow(color: purpleColor.opacity(0.08), radius: 10, x: 0, y: 5)
            
            HStack(spacing: 0) {
                // First Metric
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(purpleColor.opacity(0.08))
                            .frame(width: 40, height: 40)
                        Image(systemName: icon1)
                            .font(.system(size: 22))
                            .foregroundColor(purpleColor)
                    }
                    .padding(.bottom, 2)
                    
                    Text(value1)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                    
                    Text(title1)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(purpleColor.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                
                // Second Metric
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(purpleColor.opacity(0.08))
                            .frame(width: 40, height: 40)
                        Image(systemName: icon2)
                            .font(.system(size: 22))
                            .foregroundColor(purpleColor)
                    }
                    .padding(.bottom, 2)
                    
                    Text(value2)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                    
                    Text(title2)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(purpleColor.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 16) // Reduced from 20 to 16 (4 points less)
            .padding(.horizontal, 5)
            .frame(maxWidth: .infinity)
        }
        .scaleEffect(isTapped ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isTapped)
        .onTapGesture {
            withAnimation {
                isTapped.toggle()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isTapped.toggle()
                }
            }
        }
    }
}

// MARK: - Combined Appointments Chart
struct CombinedAppointmentsChart: View {
    let dailyAppointments: [DailyAppointmentData]
    let weeklyAppointments: [WeeklyAppointmentData]
    let monthlyAppointments: [MonthlyAppointmentData]
    private let purpleColor = Color(hex: "6D57FC")
    
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case week = "This Week"
        case weeks = "Last 6 Weeks"
        case months = "Last 6 Months"
        
        var title: String {
            switch self {
            case .week: return "Appointments This Week"
            case .weeks: return "Appointments Last 6 Weeks"
            case .months: return "Appointments Last 6 Months"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Chart Title
            Text(selectedTimeRange.title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Time Range Picker
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            
            // Chart
            Group {
                if selectedTimeRange == .week {
                    Chart(dailyAppointments) { data in
                        LineMark(
                            x: .value("Day", data.date, unit: .day),
                            y: .value("Appointments", data.count)
                        )
                        .foregroundStyle(purpleColor)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        AreaMark(
                            x: .value("Day", data.date, unit: .day),
                            y: .value("Appointments", data.count)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [purpleColor.opacity(0.25), .clear]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        PointMark(
                            x: .value("Day", data.date, unit: .day),
                            y: .value("Appointments", data.count)
                        )
                        .foregroundStyle(.white)
                        .symbolSize(60)
                        .shadow(color: purpleColor, radius: 2, x: 0, y: 0)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisGridLine()
                                .foregroundStyle(Color.gray.opacity(0.2))
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(date, format: .dateTime.day().month(.abbreviated))
                                        .font(.system(size: 10))
                                }
                            }
                        }
                    }
                } else if selectedTimeRange == .weeks {
                    Chart(weeklyAppointments) { data in
                        BarMark(
                            x: .value("Week", data.weekStart, unit: .weekOfYear),
                            y: .value("Appointments", data.count)
                        )
                        .foregroundStyle(purpleColor)
                        .cornerRadius(4)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .weekOfYear)) { value in
                            AxisGridLine()
                                .foregroundStyle(Color.gray.opacity(0.2))
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(date, format: .dateTime.day().month(.abbreviated))
                                        .font(.system(size: 10))
                                }
                            }
                        }
                    }
                } else {
                    Chart(monthlyAppointments) { data in
                        BarMark(
                            x: .value("Month", data.monthStart, unit: .month),
                            y: .value("Appointments", data.count)
                        )
                        .foregroundStyle(purpleColor)
                        .cornerRadius(4)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { value in
                            AxisGridLine()
                                .foregroundStyle(Color.gray.opacity(0.2))
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(date, format: .dateTime.month(.abbreviated))
                                        .font(.system(size: 10))
                                }
                            }
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.gray.opacity(0.2))
                    AxisValueLabel()
                        .font(.system(size: 10))
                }
            }
            .frame(height: 220)
            .padding(.top, 5)
        }
    }
}

// MARK: - Analytics Manager
class AnalyticsManager: ObservableObject {
    @Published var totalAppointments: Int = 0
    @Published var cancellationRate: Double = 0.0
    @Published var totalRevenue: Double = 0.0
    @Published var averageRevenuePerAppointment: Double = 0.0
    @Published var appointmentsByStatus: [(status: String, count: Int)] = []
    @Published var dailyAppointments: [DailyAppointmentData] = []
    @Published var weeklyAppointments: [WeeklyAppointmentData] = []
    @Published var monthlyAppointments: [MonthlyAppointmentData] = []
    @Published var isLoading: Bool = false
    
    private let db = Firestore.firestore()
    
    func fetchAnalytics() {
        isLoading = true
        
        db.collection("appointments").getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching appointments: \(error.localizedDescription)")
                self.isLoading = false
                return
            }
            
            guard let documents = snapshot?.documents else {
                self.isLoading = false
                return
            }
            
            let today = Calendar.current.startOfDay(for: Date())
            
            let appointments: [Appointment] = documents.compactMap { doc in
                let data = doc.data()
                
                guard let apptId = data["apptId"] as? String,
                      let patientId = data["patientId"] as? String,
                      let description = data["description"] as? String,
                      let docId = data["docId"] as? String,
                      let status = data["status"] as? String,
                      let billingStatus = data["billingStatus"] as? String else {
                    print("Missing required fields for document \(doc.documentID)")
                    return nil
                }
                
                let amount = data["amount"] as? Double
                let doctorsNotes = data["doctorsNotes"] as? String
                let prescriptionId = data["prescriptionId"] as? String
                let followUpRequired = data["followUpRequired"] as? Bool
                
                var date: Date?
                if let dateTimestamp = data["date"] as? Timestamp {
                    date = dateTimestamp.dateValue()
                } else if let dateString = data["date"] as? String {
                    let fullDateFormatter = DateFormatter()
                    fullDateFormatter.dateFormat = "d MMM yyyy 'at' HH:mm:ss 'UTC'Z"
                    let dateOnlyFormatter = DateFormatter()
                    dateOnlyFormatter.dateFormat = "d MMM yyyy"
                    if let parsedDate = fullDateFormatter.date(from: dateString) {
                        date = parsedDate
                    } else if let parsedDateOnly = dateOnlyFormatter.date(from: dateString) {
                        date = Calendar.current.startOfDay(for: parsedDateOnly)
                    }
                }
                if date == nil {
                    date = today
                }
                
                var followUpDate: Date?
                if let followUpTimestamp = data["followUpDate"] as? Timestamp {
                    followUpDate = followUpTimestamp.dateValue()
                } else if let followUpDateString = data["followUpDate"] as? String {
                    let fullDateFormatter = DateFormatter()
                    fullDateFormatter.dateFormat = "d MMM yyyy 'at' HH:mm:ss 'UTC'Z"
                    let dateOnlyFormatter = DateFormatter()
                    dateOnlyFormatter.dateFormat = "d MMM yyyy"
                    if let parsedFollowUpDate = fullDateFormatter.date(from: followUpDateString) {
                        followUpDate = parsedFollowUpDate
                    } else if let parsedFollowUpDateOnly = dateOnlyFormatter.date(from: followUpDateString) {
                        followUpDate = Calendar.current.startOfDay(for: parsedFollowUpDateOnly)
                    }
                }
                if followUpDate == nil && followUpRequired == true {
                    followUpDate = today
                }
                
                return Appointment(
                    id: doc.documentID,
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
            }
            
            self.calculateAnalytics(from: appointments)
            self.isLoading = false
        }
    }
    
    private func calculateAnalytics(from appointments: [Appointment]) {
        totalAppointments = appointments.count
        
        let cancelledAppointments = appointments.filter { $0.billingStatus == "cancelled" }.count
        cancellationRate = totalAppointments > 0 ? (Double(cancelledAppointments) / Double(totalAppointments)) * 100 : 0.0
        
        let totalRevenue = appointments.compactMap { $0.amount }.reduce(0, +)
        self.totalRevenue = totalRevenue
        self.averageRevenuePerAppointment = totalAppointments > 0 ? totalRevenue / Double(totalAppointments) : 0.0
        
        var statusDict: [String: Int] = [:]
        for appt in appointments {
            let status = appt.status.lowercased()
            statusDict[status, default: 0] += 1
        }
        appointmentsByStatus = statusDict.map { (status: $0.key, count: $0.value) }
            .sorted { $0.status < $1.status }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Current Week (Monday to Sunday)
        let weekday = calendar.component(.weekday, from: today)
        let daysToMonday = (weekday + 5) % 7 // Days to subtract to get to Monday
        guard let weekStart = calendar.date(byAdding: .day, value: -daysToMonday, to: today) else { return }
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else { return }
        
        var dailyDict: [Date: Int] = [:]
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: weekStart) else { continue }
            dailyDict[date] = 0
        }
        
        for appt in appointments {
            if let date = appt.date, date >= weekStart, date <= weekEnd {
                let startOfDay = calendar.startOfDay(for: date)
                dailyDict[startOfDay, default: 0] += 1
            }
        }
        
        dailyAppointments = dailyDict.map { DailyAppointmentData(date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
        
        // Last 6 Weeks (Updated to match UI)
        let sixWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -6, to: today)!
        var weeklyDict: [Date: Int] = [:]
        
        for i in 0..<6 {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: today) else { continue }
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart)
            guard let adjustedWeekStart = calendar.date(from: components) else { continue }
            weeklyDict[adjustedWeekStart] = 0
        }
        
        for appt in appointments {
            if let date = appt.date, date >= sixWeeksAgo {
                let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
                if let weekStart = calendar.date(from: components) {
                    weeklyDict[weekStart, default: 0] += 1
                }
            }
        }
        
        weeklyAppointments = weeklyDict.map { WeeklyAppointmentData(weekStart: $0.key, count: $0.value) }
            .sorted { $0.weekStart < $1.weekStart }
        
        // Last 6 Months
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: today)!
        var monthlyDict: [Date: Int] = [:]
        
        for i in 0..<6 {
            guard let monthStart = calendar.date(byAdding: .month, value: -i, to: today) else { continue }
            let components = calendar.dateComponents([.year, .month], from: monthStart)
            guard let adjustedMonthStart = calendar.date(from: components) else { continue }
            monthlyDict[adjustedMonthStart] = 0
        }
        
        for appt in appointments {
            if let date = appt.date, date >= sixMonthsAgo {
                let components = calendar.dateComponents([.year, .month], from: date)
                if let monthStart = calendar.date(from: components) {
                    monthlyDict[monthStart, default: 0] += 1
                }
            }
        }
        
        monthlyAppointments = monthlyDict.map { MonthlyAppointmentData(monthStart: $0.key, count: $0.value) }
            .sorted { $0.monthStart < $1.monthStart }
    }
}
// MARK: - Preview
struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
    }
}
