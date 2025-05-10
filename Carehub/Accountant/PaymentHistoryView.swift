//import SwiftUI
//import Firebase
//
//struct PaymentHistoryView: View {
//    @StateObject private var viewModel = PaymentsViewModel()
//    @State private var searchText = ""
//    @State private var showFilters = false
//    @State private var selectedPaymentMode: String?
//    @State private var selectedDateRange: DateRange?
//    @State private var isPresentingDatePicker = false
//    @State private var startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
//    @State private var endDate = Date()
//    
//    private let primaryColor = Color(hex: "#6D57FC")
//    let secondaryColor = Color(UIColor { traitCollection in
//        traitCollection.userInterfaceStyle == .dark
//            ? UIColor.systemGray5
//            : UIColor.systemGray6
//    })
//    
//    private var filteredPayments: [Billing] {
//        var filtered = viewModel.payments
//        
//        // Apply search filter
//        if !searchText.isEmpty {
//            filtered = filtered.filter { payment in
//                let patientNameMatch = viewModel.patientNames[payment.patientId]?.localizedCaseInsensitiveContains(searchText) ?? false
//                let doctorNameMatch = viewModel.doctorNames[payment.doctorId]?.localizedCaseInsensitiveContains(searchText) ?? false
//                
//                return payment.patientId.localizedCaseInsensitiveContains(searchText) ||
//                    payment.billingId.localizedCaseInsensitiveContains(searchText) ||
//                    patientNameMatch ||
//                    doctorNameMatch
//            }
//        }
//        
//        // Apply payment mode filter
//        if let mode = selectedPaymentMode {
//            filtered = filtered.filter { $0.paymentMode == mode }
//        }
//        
//        // Apply date range filter
//        if let dateRange = selectedDateRange, dateRange != .all {
//            let calendar = Calendar.current
//            let now = Date()
//            
//            switch dateRange {
//            case .today:
//                filtered = filtered.filter { calendar.isDateInToday($0.date) }
//            case .thisWeek:
//                if let startOfWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date {
//                    filtered = filtered.filter { $0.date >= startOfWeek && $0.date <= now }
//                }
//            case .thisMonth:
//                if let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) {
//                    filtered = filtered.filter { $0.date >= startOfMonth && $0.date <= now }
//                }
//            case .custom:
//                filtered = filtered.filter { $0.date >= startDate && $0.date <= endDate }
//            case .all:
//                break
//            }
//        }
//        
//        return filtered
//    }
//    
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 0) {
//                // Search and filter bar combined
//                VStack(spacing: 12) {
//                    HStack(spacing: 8) {
//                        // Search bar
//                        HStack {
//                            Image(systemName: "magnifyingglass")
//                                .foregroundColor(.gray)
//                            
//                            TextField("Search by ID or name", text: $searchText)
//                                .foregroundColor(.primary)
//                            
//                            if !searchText.isEmpty {
//                                Button(action: {
//                                    searchText = ""
//                                }) {
//                                    Image(systemName: "xmark.circle.fill")
//                                        .foregroundColor(.gray)
//                                }
//                            }
//                        }
//                        .padding(.vertical, 8)
//                        .padding(.horizontal, 12)
//                        .background(Color(.systemGray6))
//                        .cornerRadius(10)
//                        
//                        // Filter button
//                        Button(action: {
//                            withAnimation {
//                                showFilters.toggle()
//                            }
//                        }) {
//                            HStack {
//                                Image(systemName: "line.3.horizontal.decrease.circle")
//                                    .foregroundColor(primaryColor)
//                            }
//                            .padding(.vertical, 8)
//                            .padding(.horizontal, 12)
//                            .background(secondaryColor)
//                            .cornerRadius(10)
//                            .overlay(
//                                Group {
//                                    if selectedPaymentMode != nil || selectedDateRange != nil {
//                                        Circle()
//                                            .fill(primaryColor)
//                                            .frame(width: 8, height: 8)
//                                            .offset(x: 10, y: -10)
//                                    }
//                                }
//                            )
//                        }
//                    }
//                    
//                    // Active filters
//                    if selectedPaymentMode != nil || selectedDateRange != nil {
//                        HStack {
//                            ScrollView(.horizontal, showsIndicators: false) {
//                                HStack(spacing: 8) {
//                                    if let mode = selectedPaymentMode {
//                                        ActiveFilterChip(text: mode) {
//                                            selectedPaymentMode = nil
//                                        }
//                                    }
//                                    
//                                    if let range = selectedDateRange, range != .all {
//                                        ActiveFilterChip(text: range.displayName) {
//                                            selectedDateRange = nil
//                                        }
//                                    }
//                                }
//                                .padding(.trailing, 8)
//                            }
//                            
//                            Button(action: {
//                                selectedPaymentMode = nil
//                                selectedDateRange = nil
//                            }) {
//                                Text("Clear")
//                                    .font(.footnote)
//                                    .foregroundColor(primaryColor)
//                            }
//                        }
//                    }
//                }
//                .padding(.horizontal)
//                .padding(.top, 8)
//                
//                // Filter options
//                if showFilters {
//                    VStack(alignment: .leading, spacing: 12) {
//                        Text("Payment Mode")
//                            .font(.subheadline)
//                            .fontWeight(.medium)
//                            .foregroundColor(.primary)
//                        
//                        ScrollView(.horizontal, showsIndicators: false) {
//                            HStack(spacing: 8) {
//                                ForEach(["UPI", "Card", "Cash", "Insurance"], id: \.self) { mode in
//                                    FilterChip(
//                                        text: mode,
//                                        isSelected: selectedPaymentMode == mode,
//                                        action: {
//                                            if selectedPaymentMode == mode {
//                                                selectedPaymentMode = nil
//                                            } else {
//                                                selectedPaymentMode = mode
//                                            }
//                                        }
//                                    )
//                                }
//                            }
//                        }
//                        
//                        Text("Date Range")
//                            .font(.subheadline)
//                            .fontWeight(.medium)
//                            .foregroundColor(.primary)
//                            .padding(.top, 4)
//                        
//                        ScrollView(.horizontal, showsIndicators: false) {
//                            HStack(spacing: 8) {
//                                ForEach(DateRange.allCases, id: \.self) { range in
//                                    FilterChip(
//                                        text: range.displayName,
//                                        isSelected: selectedDateRange == range,
//                                        action: {
//                                            if range == .custom {
//                                                isPresentingDatePicker = true
//                                            } else if selectedDateRange == range {
//                                                selectedDateRange = nil
//                                            } else {
//                                                selectedDateRange = range
//                                            }
//                                        }
//                                    )
//                                }
//                            }
//                        }
//                        
//                        if selectedDateRange == .custom {
//                            Text("From \(startDate.formatted(date: .abbreviated, time: .omitted)) to \(endDate.formatted(date: .abbreviated, time: .omitted))")
//                                .font(.footnote)
//                                .foregroundColor(.secondary)
//                        }
//                    }
//                    .padding()
//                    .background(Color(.systemGray6).opacity(0.5))
//                    .cornerRadius(10)
//                    .padding(.horizontal)
//                    .padding(.top, 4)
//                }
//                
//                // Main content
//                Group {
//                    if let error = viewModel.error {
//                        PaymentsErrorView(error: error)
//                    } else if viewModel.isLoading {
//                        PaymentsLoadingView()
//                    } else if filteredPayments.isEmpty {
//                        PaymentsEmptyStateView(searchText: searchText)
//                    } else {
//                        ScrollView {
//                            LazyVStack(spacing: 12) {
//                                ForEach(filteredPayments) { bill in
//                                    ImprovedPaymentCard(bill: bill, viewModel: viewModel)
//                                }
//                            }
//                            .padding(.horizontal)
//                            .padding(.vertical, 12)
//                        }
//                        .refreshable {
//                            viewModel.getBills()
//                        }
//                    }
//                }
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//            }
//            .sheet(isPresented: $isPresentingDatePicker) {
//                DatePickerView(startDate: $startDate, endDate: $endDate) {
//                    selectedDateRange = .custom
//                    isPresentingDatePicker = false
//                }
//            }
//            .navigationTitle("Payment History")
//            .navigationBarTitleDisplayMode(.large)
//            .onAppear {
//                viewModel.getBills()
//            }
//        }
//    }
//}
//
//// MARK: - Redesigned Payment Card
//
//struct ImprovedPaymentCard: View {
//    let bill: Billing
//    let viewModel: PaymentsViewModel
//    let billViewModel: GenerateBillViewModel
//    @State private var showBillItems = false
//    @Environment(\.colorScheme) var colorScheme
//    
//    private let primaryColor = Color(hex: "#6D57FC")
//    private let secondaryColor = Color(hex: "#F5F3FF")
//    private let darkModeBgColor = Color(hex: "#1C1C1E")
//    private let lightModeBgColor = Color(.systemBackground)
//    
//    private var backgroundColor: Color {
//        colorScheme == .dark ? darkModeBgColor : lightModeBgColor
//    }
//    
//    private var secondaryBackgroundColor: Color {
//        colorScheme == .dark ? Color(hex: "#2C2C2E") : secondaryColor
//    }
//    
//    private var shadowColor: Color {
//        colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.08)
//    }
//    
//    private var dividerColor: Color {
//        colorScheme == .dark ? Color(hex: "#38383A") : Color(hex: "#ECECEC")
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            // Header with amount and status
//            HStack(alignment: .top) {
//                VStack(alignment: .leading, spacing: 4) {
//                    Text("₹\(String(format: "%.2f", bill.paidAmt))")
//                        .font(.system(size: 22, weight: .semibold, design: .rounded))
//                        .foregroundColor(colorScheme == .dark ? .white : .primary)
//
//                    Button(action: {
//                        if let url = URL(string: bill.billingId) {
//                            billViewModel.presentPDFViewer(with: url)
//                        }
//                    }) {
//                        Text("View Bill")
//                            .font(.system(size: 12, weight: .medium))
//                            .foregroundColor(.blue)
//                            .underline()
//                    }
//                }
//
//                Spacer()
//
//                PaymentStatusBadge(status: bill.billingStatus)
//                    .padding(.top, 2)
//            }
//
//            .padding(16)
//            
//            // Metadata rowxa/xa
//            HStack(spacing: 12) {
//                HStack(spacing: 6) {
//                    Image(systemName: "calendar")
//                        .font(.system(size: 12))
//                        .foregroundColor(primaryColor)
//                    
//                    Text(bill.date.formatted(date: .abbreviated, time: .shortened))
//                        .font(.system(size: 12, weight: .medium))
//                        .foregroundColor(colorScheme == .dark ? Color(hex: "#AAAAAA") : .secondary)
//                }
//                
//                Circle()
//                    .frame(width: 4, height: 4)
//                    .foregroundColor(colorScheme == .dark ? Color(hex: "#444444") : Color.secondary.opacity(0.4))
//                
//                HStack(spacing: 6) {
//                    Image(systemName: paymentModeIcon)
//                        .font(.system(size: 12))
//                        .foregroundColor(primaryColor)
//                    
//                    Text(bill.paymentMode)
//                        .font(.system(size: 12, weight: .medium))
//                        .foregroundColor(colorScheme == .dark ? Color(hex: "#AAAAAA") : .secondary)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.bottom, 16)
//            
//            // Patient and doctor info
//            HStack(spacing: 12) {
//                infoPill(
//                    icon: "person.fill",
//                    title: viewModel.patientNames[bill.patientId] ?? "Patient",
//                    subtitle: "ID: \(bill.patientId)"
//                )
//                
//                Spacer()
//                
//                infoPill(
//                    icon: "stethoscope",
//                    title: viewModel.doctorNames[bill.doctorId] ?? "Doctor",
//                    subtitle: "ID: \(bill.doctorId)"
//                )
//            }
//            .padding(.horizontal, 16)
//            .padding(.bottom, 16)
//            
//            // Bill items section
//            if !bill.bills.isEmpty {
//                VStack(spacing: 0) {
//                    Divider()
//                        .background(dividerColor)
//                    
//                    Button(action: {
//                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                            showBillItems.toggle()
//                        }
//                    }) {
//                        HStack {
//                            Text("Bill Items (\(bill.bills.count))")
//                                .font(.system(size: 12, weight: .semibold))
//                                .foregroundColor(primaryColor)
//                            
//                            Spacer()
//                            
//                            Image(systemName: showBillItems ? "chevron.up" : "chevron.down")
//                                .font(.system(size: 12, weight: .bold))
//                                .foregroundColor(primaryColor)
//                        }
//                        .padding(16)
//                        .contentShape(Rectangle())
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                    
//                    if showBillItems {
//                        VStack(spacing: 0) {
//                            ForEach(bill.bills.indices, id: \.self) { index in
//                                HStack {
//                                    Text(bill.bills[index].itemName)
//                                        .font(.system(size: 13, weight: .medium))
//                                        .foregroundColor(colorScheme == .dark ? .white : .primary)
//                                    
//                                    Spacer()
//                                    
//                                    Text("₹\(String(format: "%.2f", bill.bills[index].fee))")
//                                        .font(.system(size: 13, weight: .semibold))
//                                        .foregroundColor(colorScheme == .dark ? .white : .primary)
//                                }
//                                .padding(.horizontal, 16)
//                                .padding(.vertical, 10)
//                                
//                                if index < bill.bills.count - 1 {
//                                    Divider()
//                                        .background(dividerColor)
//                                        .padding(.leading, 16)
//                                }
//                            }
//                        }
//                        .background(secondaryBackgroundColor)
//                        .transition(.opacity.combined(with: .move(edge: .top)))
//                    }
//                }
//            }
//            
//            // Insurance info if applicable
//            if bill.insuranceAmt > 0 {
//                VStack(spacing: 0) {
//                    Divider()
//                        .background(dividerColor)
//                    
//                    HStack {
//                        Text("Insurance Coverage")
//                            .font(.system(size: 12, weight: .semibold))
//                            .foregroundColor(colorScheme == .dark ? Color(hex: "#AAAAAA") : .secondary)
//                        
//                        Spacer()
//                        
//                        Text("₹\(String(format: "%.2f", bill.insuranceAmt))")
//                            .font(.system(size: 14, weight: .semibold))
//                            .foregroundColor(primaryColor)
//                    }
//                    .padding(16)
//                }
//            }
//        }
//        .background(backgroundColor)
//        .cornerRadius(14)
//        .shadow(color: shadowColor, radius: 10, x: 0, y: 4)
//        .padding(.horizontal, 1)
//    }
//    
//    private var paymentModeIcon: String {
//           switch bill.paymentMode.lowercased() {
//           case "upi": return "iphone"
//           case "card": return "creditcard"
//           case "insurance": return "doc.text"
//           default: return "banknote"
//           }
//       }
//       
//       private func infoPill(icon: String, title: String, subtitle: String) -> some View {
//           HStack(spacing: 10) {
//               Image(systemName: icon)
//                   .font(.system(size: 12))
//                   .foregroundColor(primaryColor)
//                   .frame(width: 24, height: 24)
//                   .background(primaryColor.opacity(0.1))
//                   .clipShape(Circle())
//               
//               VStack(alignment: .leading, spacing: 2) {
//                   Text(title)
//                       .font(.system(size: 13, weight: .medium))
//                       .lineLimit(1)
//                   
//                   Text(subtitle)
//                       .font(.system(size: 11, weight: .medium))
//                       .foregroundColor(.secondary)
//               }
//           }
//       }
//}
//// MARK: - Supporting Components
//struct FilterChip: View {
//    let text: String
//    let isSelected: Bool
//    let action: () -> Void
//
//    private let primaryColor = Color(hex: "#6D57FC")
//    
//    var secondaryColor: Color {
//        Color(UIColor { traitCollection in
//            return traitCollection.userInterfaceStyle == .dark
//                ? UIColor.systemGray5
//                : UIColor.systemGray6
//        })
//    }
//    
//    var body: some View {
//        Button(action: action) {
//            Text(text)
//                .font(.subheadline)
//                .foregroundColor(isSelected ? .white : primaryColor)
//                .padding(.vertical, 6)
//                .padding(.horizontal, 12)
//                .background(isSelected ? primaryColor : secondaryColor)
//                .cornerRadius(16)
//        }
//    }
//}
//
//struct ActiveFilterChip: View {
//    let text: String
//    let onRemove: () -> Void
//    
//    private let primaryColor = Color(hex: "#6D57FC")
//    
//    var body: some View {
//        HStack(spacing: 4) {
//            Text(text)
//                .font(.footnote)
//                .foregroundColor(primaryColor)
//            
//            Button(action: onRemove) {
//                Image(systemName: "xmark")
//                    .font(.caption)
//                    .foregroundColor(primaryColor)
//            }
//        }
//        .padding(.vertical, 5)
//        .padding(.horizontal, 10)
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .stroke(primaryColor, lineWidth: 1)
//        )
//    }
//}
//
//struct PaymentStatusBadge: View {
//    let status: String
//    
//    var statusColor: Color {
//        switch status.lowercased() {
//        case "paid":
//            return Color.green
//        case "partial":
//            return Color.orange
//        case "pending":
//            return Color.red
//        default:
//            return Color.gray
//        }
//    }
//    
//    var body: some View {
//        Text(status.capitalized)
//            .font(.caption)
//            .fontWeight(.medium)
//            .foregroundColor(.white)
//            .padding(.horizontal, 10)
//            .padding(.vertical, 4)
//            .background(statusColor)
//            .cornerRadius(12)
//    }
//}
//
//struct PaymentsErrorView: View {
//    let error: Error
//    
//    var body: some View {
//        VStack(spacing: 16) {
//            Image(systemName: "exclamationmark.triangle")
//                .font(.system(size: 50))
//                .foregroundColor(.orange)
//            
//            Text("Error Occurred")
//                .font(.headline)
//            
//            Text(error.localizedDescription)
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//                .multilineTextAlignment(.center)
//                .padding(.horizontal)
//            
//            Button(action: {
//                // Retry action would go here
//            }) {
//                Text("Try Again")
//                    .fontWeight(.semibold)
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 24)
//                    .padding(.vertical, 12)
//                    .background(Color(hex: "#6D57FC"))
//                    .cornerRadius(10)
//            }
//        }
//        .padding()
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//}
//
//struct PaymentsLoadingView: View {
//    var body: some View {
//        VStack(spacing: 20) {
//            ProgressView()
//                .scaleEffect(1.5)
//            
//            Text("Loading payments...")
//                .foregroundColor(.secondary)
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//}
//
//struct PaymentsEmptyStateView: View {
//    let searchText: String
//    
//    var body: some View {
//        VStack(spacing: 16) {
//            Image(systemName: "doc.text.magnifyingglass")
//                .font(.system(size: 50))
//                .foregroundColor(Color(hex: "#6D57FC").opacity(0.8))
//            
//            if !searchText.isEmpty {
//                Text("No results found")
//                    .font(.headline)
//                
//                Text("We couldn't find any payments matching '\(searchText)'")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                    .multilineTextAlignment(.center)
//                    .padding(.horizontal)
//            } else {
//                Text("No payments available")
//                    .font(.headline)
//                
//                Text("You have no payment history to display")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//            }
//        }
//        .padding()
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//}
//
//struct DatePickerView: View {
//    @Binding var startDate: Date
//    @Binding var endDate: Date
//    @Environment(\.presentationMode) var presentationMode
//    let onSave: () -> Void
//    
//    private let primaryColor = Color(hex: "#6D57FC")
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                Form {
//                    Section(header: Text("Start Date")) {
//                        DatePicker("", selection: $startDate, displayedComponents: .date)
//                            .datePickerStyle(.graphical)
//                            .accentColor(primaryColor)
//                    }
//                    
//                    Section(header: Text("End Date")) {
//                        DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
//                            .datePickerStyle(.graphical)
//                            .accentColor(primaryColor)
//                    }
//                }
//            }
//            .navigationTitle("Select Date Range")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Cancel") {
//                        presentationMode.wrappedValue.dismiss()
//                    }
//                }
//                
//                ToolbarItem(placement: .confirmationAction) {
//                    Button("Apply") {
//                        onSave()
//                    }
//                    .foregroundColor(primaryColor)
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Enums
//
//enum DateRange: CaseIterable {
//    case today
//    case thisWeek
//    case thisMonth
//    case custom
//    case all
//    
//    var displayName: String {
//        switch self {
//        case .today: return "Today"
//        case .thisWeek: return "This Week"
//        case .thisMonth: return "This Month"
//        case .custom: return "Custom Range"
//        case .all: return "All Time"
//        }
//    }
//}
//
//struct PaymentHistoryView_Previews: PreviewProvider {
//    static var previews: some View {
//        PaymentHistoryView()
//    }
//}

import SwiftUI
import Firebase

struct PaymentHistoryView: View {
    @StateObject private var viewModel = PaymentsViewModel()
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var selectedPaymentMode: String?
    @State private var selectedDateRange: DateRange?
    @State private var isPresentingDatePicker = false
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var selectedBillForDetail: Billing? = nil
    
    private let primaryColor = Color(hex: "#6D57FC")
    
    private var filteredPayments: [Billing] {
        var filtered = viewModel.payments
        
        if !searchText.isEmpty {
            filtered = filtered.filter { payment in
                let patientNameMatch = viewModel.patientNames[payment.patientId]?.localizedCaseInsensitiveContains(searchText) ?? false
                let doctorNameMatch = viewModel.doctorNames[payment.doctorId]?.localizedCaseInsensitiveContains(searchText) ?? false
                
                return payment.patientId.localizedCaseInsensitiveContains(searchText) ||
                    payment.billingId.localizedCaseInsensitiveContains(searchText) ||
                    patientNameMatch ||
                    doctorNameMatch
            }
        }
        
        if let mode = selectedPaymentMode {
            filtered = filtered.filter { $0.paymentMode == mode }
        }
        
        if let dateRange = selectedDateRange, dateRange != .all {
            filtered = applyDateRangeFilter(filtered, dateRange: dateRange)
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchAndFilterBar(
                    searchText: $searchText,
                    showFilters: $showFilters,
                    selectedPaymentMode: $selectedPaymentMode,
                    selectedDateRange: $selectedDateRange,
                    startDate: $startDate,
                    endDate: $endDate,
                    isPresentingDatePicker: $isPresentingDatePicker,
                    primaryColor: primaryColor
                )
                
                if showFilters {
                    FilterOptionsView(
                        selectedPaymentMode: $selectedPaymentMode,
                        selectedDateRange: $selectedDateRange,
                        isPresentingDatePicker: $isPresentingDatePicker,
                        startDate: startDate,
                        endDate: endDate,
                        primaryColor: primaryColor
                    )
                }
                
                PaymentContentArea(
                    viewModel: viewModel,
                    filteredPayments: filteredPayments,
                    searchText: searchText,
                    selectedBillForDetail: $selectedBillForDetail
                )
            }
            .sheet(isPresented: $isPresentingDatePicker) {
                DatePickerView(
                    startDate: $startDate,
                    endDate: $endDate,
                    primaryColor: primaryColor
                ) {
                    selectedDateRange = .custom
                    isPresentingDatePicker = false
                }
            }
            .sheet(item: $selectedBillForDetail) { bill in
                BillItemsPopup(bill: bill)
            }
            .navigationTitle("Payment History")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.getBills()
            }
        }
    }
    
    private func applyDateRangeFilter(_ payments: [Billing], dateRange: DateRange) -> [Billing] {
        let calendar = Calendar.current
        let now = Date()
        var filtered = payments
        
        switch dateRange {
        case .today:
            filtered = filtered.filter { calendar.isDateInToday($0.date) }
        case .thisWeek:
            if let startOfWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date {
                filtered = filtered.filter { $0.date >= startOfWeek && $0.date <= now }
            }
        case .thisMonth:
            if let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) {
                filtered = filtered.filter { $0.date >= startOfMonth && $0.date <= now }
            }
        case .custom:
            filtered = filtered.filter { $0.date >= startDate && $0.date <= endDate }
        case .all:
            break
        }
        
        return filtered
    }
}

struct SearchAndFilterBar: View {
    @Binding var searchText: String
    @Binding var showFilters: Bool
    @Binding var selectedPaymentMode: String?
    @Binding var selectedDateRange: DateRange?
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isPresentingDatePicker: Bool
    
    let primaryColor: Color
    
    private var secondaryColor: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.systemGray5
                : UIColor.systemGray6
        })
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search by ID or name", text: $searchText)
                        .foregroundColor(.primary)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Filter button
                Button(action: {
                    withAnimation {
                        showFilters.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(primaryColor)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(secondaryColor)
                    .cornerRadius(10)
                    .overlay(
                        Group {
                            if selectedPaymentMode != nil || selectedDateRange != nil {
                                Circle()
                                    .fill(primaryColor)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 10, y: -10)
                            }
                        }
                    )
                }
            }
            
            // Active filters
            if selectedPaymentMode != nil || selectedDateRange != nil {
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if let mode = selectedPaymentMode {
                                ActiveFilterChip(text: mode) {
                                    selectedPaymentMode = nil
                                }
                            }
                            
                            if let range = selectedDateRange, range != .all {
                                ActiveFilterChip(text: range.displayName) {
                                    selectedDateRange = nil
                                }
                            }
                        }
                        .padding(.trailing, 8)
                    }
                    
                    Button(action: {
                        selectedPaymentMode = nil
                        selectedDateRange = nil
                    }) {
                        Text("Clear")
                            .font(.footnote)
                            .foregroundColor(primaryColor)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct FilterOptionsView: View {
    @Binding var selectedPaymentMode: String?
    @Binding var selectedDateRange: DateRange?
    @Binding var isPresentingDatePicker: Bool
    
    let startDate: Date
    let endDate: Date
    let primaryColor: Color
    
    var paymentModeChips: some View {
        ForEach(["UPI", "Card", "Cash", "Insurance"], id: \.self) { mode in
            FilterChip(
                text: mode,
                isSelected: selectedPaymentMode == mode,
                action: {
                    if selectedPaymentMode == mode {
                        selectedPaymentMode = nil
                    } else {
                        selectedPaymentMode = mode
                    }
                }, primaryColor: Color(hex: "#6D57FC")
            )
        }
    }

    var dateRangeChips: some View {
        ForEach(DateRange.allCases, id: \.self) { range in
            FilterChip(
                text: range.displayName,
                isSelected: selectedDateRange == range,
                action: {
                    if range == .custom {
                        isPresentingDatePicker = true
                    } else if selectedDateRange == range {
                        selectedDateRange = nil
                    } else {
                        selectedDateRange = range
                    }
                }, primaryColor: Color(hex: "#6D57FC")
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Mode")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    paymentModeChips
                }
            }
            
            Text("Date Range")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .padding(.top, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    dateRangeChips
                }
            }
            
            if selectedDateRange == .custom {
                Text("From \(startDate.formatted(date: .abbreviated, time: .omitted)) to \(endDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 4)
    }

}

struct PaymentContentArea: View {
    @ObservedObject var viewModel: PaymentsViewModel
    let filteredPayments: [Billing]
    let searchText: String
    @Binding var selectedBillForDetail: Billing?
    
    var body: some View {
//        Group {
            if let error = viewModel.error {
                PaymentsErrorView(error: error)
            } else if viewModel.isLoading {
                PaymentsLoadingView()
            } else if filteredPayments.isEmpty {
                PaymentsEmptyStateView(searchText: searchText)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredPayments) { bill in
                            PaymentCard(
                                bill: bill,
                                viewModel: viewModel, billViewModel: GenerateBillViewModel(),
                                onViewBillItems: {
                                    selectedBillForDetail = bill
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .refreshable {
                    viewModel.getBills()
                }
            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PaymentCard: View {
    let bill: Billing
    let viewModel: PaymentsViewModel
    let billViewModel : GenerateBillViewModel
    let onViewBillItems: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    private let primaryColor = Color(hex: "#6D57FC")
    private let darkModeBgColor = Color(hex: "#1C1C1E")
    private let lightModeBgColor = Color(.systemBackground)
    
    private var backgroundColor: Color {
        colorScheme == .dark ? darkModeBgColor : lightModeBgColor
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.08)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with amount and status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("₹\(String(format: "%.2f", bill.paidAmt))")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
//                    if let url = URL(string: bill.billURL!) {
                        Button(action: {
                            billViewModel.presentPDFViewer(with: URL(string:bill.billingId)!)
                        }) {
                            Text("View Bill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                                .underline()
                        }
//                    }

                }
                
                Spacer()
                
                PaymentStatusBadge(status: bill.billingStatus)
                    .padding(.top, 2)
            }
            .padding(16)
            
            // Metadata row
            PaymentMetadataRow(bill: bill, primaryColor: primaryColor)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            
            // Patient and doctor info
            HStack(spacing: 12) {
                InfoPill(
                    icon: "person.fill",
                    title: viewModel.patientNames[bill.patientId] ?? "Patient",
                    subtitle: "ID: \(bill.patientId)",
                    primaryColor: primaryColor
                )
                
                Spacer()
                
                InfoPill(
                    icon: "stethoscope",
                    title: viewModel.doctorNames[bill.doctorId] ?? "Doctor",
                    subtitle: "ID: \(bill.doctorId)",
                    primaryColor: primaryColor
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // Bill items button
            if !bill.bills.isEmpty {
                Button(action: onViewBillItems) {
                    HStack {
                        Text("View Bill Items (\(bill.bills.count))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(primaryColor)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(primaryColor)
                    }
                    .padding(16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(backgroundColor)
        .cornerRadius(14)
        .shadow(color: shadowColor, radius: 10, x: 0, y: 4)
        .padding(.horizontal, 1)
    }
}

struct PaymentMetadataRow: View {
    let bill: Billing
    let primaryColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundColor(primaryColor)
                
                Text(bill.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? Color(hex: "#AAAAAA") : .secondary)
            }
            
            Circle()
                .frame(width: 4, height: 4)
                .foregroundColor(colorScheme == .dark ? Color(hex: "#444444") : Color.secondary.opacity(0.4))
            
            HStack(spacing: 6) {
                Image(systemName: paymentModeIcon)
                    .font(.system(size: 12))
                    .foregroundColor(primaryColor)
                
                Text(bill.paymentMode)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? Color(hex: "#AAAAAA") : .secondary)
            }
        }
    }
    
    private var paymentModeIcon: String {
        switch bill.paymentMode.lowercased() {
        case "upi": return "iphone"
        case "card": return "creditcard"
        case "insurance": return "doc.text"
        default: return "banknote"
        }
    }
}

struct InfoPill: View {
    let icon: String
    let title: String
    let subtitle: String
    let primaryColor: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(primaryColor)
                .frame(width: 24, height: 24)
                .background(primaryColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct BillItemsPopup: View {
    let bill: Billing
    @Environment(\.presentationMode) var presentationMode
    
    private let primaryColor = Color(hex: "#6D57FC")
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Bill Items")) {
                    ForEach(bill.bills, id: \.itemName) { item in
                        HStack {
                            Text(item.itemName)
                                .font(.body)
                            
                            Spacer()
                            
                            Text("₹\(String(format: "%.2f", item.fee))")
                                .font(.body)
                                .foregroundColor(primaryColor)
                        }
                    }
                }
                
                if bill.insuranceAmt > 0 {
                    Section(header: Text("Insurance")) {
                        HStack {
                            Text("Coverage Amount")
                            
                            Spacer()
                            
                            Text("₹\(String(format: "%.2f", bill.insuranceAmt))")
                                .foregroundColor(primaryColor)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Bill Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct DatePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    let primaryColor: Color
    let onSave: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Start Date")) {
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .accentColor(primaryColor)
                    }
                    
                    Section(header: Text("End Date")) {
                        DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .accentColor(primaryColor)
                    }
                }
            }
            .navigationTitle("Select Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onSave()
                    }
                    .foregroundColor(primaryColor)
                }
            }
        }
    }
}

struct PaymentsErrorView: View {
    let error: Error
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Error Occurred")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                // Retry action would go here
            }) {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#6D57FC"))
                    .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PaymentsLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading payments...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PaymentsEmptyStateView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "#6D57FC").opacity(0.8))
            
            if !searchText.isEmpty {
                Text("No results found")
                    .font(.headline)
                
                Text("We couldn't find any payments matching '\(searchText)'")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("No payments available")
                    .font(.headline)
                
                Text("You have no payment history to display")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FilterChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    let primaryColor: Color
    
    private var secondaryColor: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
                ? UIColor.systemGray5
                : UIColor.systemGray6
        })
    }
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : primaryColor)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(isSelected ? primaryColor : secondaryColor)
                .cornerRadius(16)
        }
    }
}

struct ActiveFilterChip: View {
    let text: String
    let onRemove: () -> Void
    let primaryColor = Color(hex: "#6D57FC")
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.footnote)
                .foregroundColor(primaryColor)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(primaryColor)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(primaryColor, lineWidth: 1)
        )
    }
}

struct PaymentStatusBadge: View {
    let status: String
    
    var statusColor: Color {
        switch status.lowercased() {
        case "paid":
            return Color.green
        case "partial":
            return Color.orange
        case "pending":
            return Color.red
        default:
            return Color.gray
        }
    }
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(12)
    }
}

enum DateRange: CaseIterable {
    case today
    case thisWeek
    case thisMonth
    case custom
    case all
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .custom: return "Custom Range"
        case .all: return "All Time"
        }
    }
}
