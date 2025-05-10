import SwiftUI

struct StaffListView: View {
    @ObservedObject var staffManager: StaffManager
    @State private var searchText = ""
    @State private var showingAddStaff = false
    @State private var selectedRole: StaffRole? = nil
    private let purpleColor = Color(red: 0.43, green: 0.34, blue: 0.99)

    var filteredStaff: [Staff] {
        let roleFiltered = selectedRole == nil ? staffManager.staffList : staffManager.staffList.filter { $0.role == selectedRole }
        return searchText.isEmpty ? roleFiltered : roleFiltered.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            ($0.id?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.department?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.94, green: 0.94, blue: 1.0)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                            VStack(alignment: .leading, spacing: 10) {
                                SearchBar(text: $searchText, placeholder: "Search staff...")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        RoleFilterButton(role: nil, selectedRole: $selectedRole)
                                        ForEach(StaffRole.allCases) { role in
                                            RoleFilterButton(role: role, selectedRole: $selectedRole)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding()
                        }
                        
                        ForEach(filteredStaff) { staff in
                            NavigationLink(destination: StaffDetailView(staff: staff, staffManager: staffManager)) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                                    StaffRowView(staff: staff)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .onDelete(perform: deleteStaff)
                    }
                    .padding(.top, 10)
                }

                // Floating Plus Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingAddStaff = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(purpleColor)
                                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                                )
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("Staff Management")
            .sheet(isPresented: $showingAddStaff) {
                AddStaffView(staffManager: staffManager)
            }
        }
    }
    
    private func deleteStaff(at offsets: IndexSet) {
        offsets.forEach { index in
            let staff = filteredStaff[index]
            staffManager.deleteStaff(staff) { success in
                if success {
                    print("Successfully deleted staff")
                } else {
                    print("Failed to delete staff")
                }
            }
        }
    }
}

struct StaffRowView: View {
    let staff: Staff
    private let purpleColor = Color(red: 0.43, green: 0.34, blue: 0.99)

    var roleColor: Color {
        switch staff.role {
        case .doctor: return .green
        case .nurse: return .orange
        case .labTechnician: return .purple
        case .admin: return purpleColor
        case .accountant: return .yellow
        }
    }
    
    var displayId: String {
        guard let id = staff.id else { return "Unknown ID" }
        return id.count > 6 ? String(id.prefix(6)) : id
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(roleColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: staff.role == .doctor ? "stethoscope" :
                      staff.role == .nurse ? "cross.case.fill" :
                      staff.role == .labTechnician ? "testtube.2" : "person.fill")
                    .foregroundColor(roleColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(staff.fullName)
                    .font(.system(size: 16, weight: .medium))
                HStack(spacing: 6) {
                    Text(staff.role.rawValue)
                        .font(.system(size: 14))
                        .foregroundColor(roleColor)
                    Text("•")
                        .foregroundColor(.gray)
                    Text(staff.department ?? "N/A")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Text(displayId)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct RoleFilterButton: View {
    let role: StaffRole?
    @Binding var selectedRole: StaffRole?
    private let purpleColor = Color(red: 0.43, green: 0.34, blue: 0.99)

    var isSelected: Bool {
        role == selectedRole
    }
    
    var title: String {
        role?.rawValue ?? "All"
    }
    
    var color: Color {
        guard let role = role else { return purpleColor }
        switch role {
        case .doctor: return .green
        case .nurse: return .orange
        case .labTechnician: return .purple
        case .admin: return purpleColor
        case .accountant: return .yellow
        }
    }
    
    var body: some View {
        Button {
            selectedRole = role
        } label: {
            Text(title)
                .font(.system(size: 14))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color.opacity(0.2) : Color(.systemBackground))
                .foregroundColor(isSelected ? color : .primary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? color : Color(.systemGray4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
