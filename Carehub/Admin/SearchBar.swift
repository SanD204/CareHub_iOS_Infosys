
import SwiftUI
// SearchBar.swift
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(10)
    }
}

struct RecentActivityView: View {
    @ObservedObject var staffManager: StaffManager
    private let purpleColor = Color(red: 0.43, green: 0.34, blue: 0.99)

    var recentStaff: [Staff] {
        Array(staffManager.staffList
            .filter { $0.joinDate != nil }
            .sorted(by: { $0.joinDate! > $1.joinDate! })
            .prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Additions")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.top, 10)
            
            if recentStaff.isEmpty {
                Text("No recent staff available")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    VStack(spacing: 12) {
                        ForEach(recentStaff) { staff in
                            HStack(spacing: 12) {
                                StaffAvatarView(role: staff.role)
                                    .frame(width: 40, height: 40)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(staff.fullName)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    Text("\(staff.role.rawValue) • \(staff.department ?? "N/A")")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Text(staff.joinDate?.formatted(date: .numeric, time: .omitted) ?? "N/A")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 12)
                        }
                    }
                    .padding(.vertical, 12)
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
