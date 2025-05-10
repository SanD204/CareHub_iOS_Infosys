//
//  ChatView.swift
//  Carehub
//
//  Created by Yash Gupta on 08/05/25.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.97, blue: 1.0)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HeaderView()
                
                MessagesListView(viewModel: viewModel)
                
                InputView(viewModel: viewModel)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

private struct HeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "cross.circle.fill")
                .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                .font(.title2)
            Text("HealthCare Pro")
                .font(.title2.bold())
                .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
            Spacer()
        }
        .padding()
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
}

private struct MessagesListView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var showSymptomButtons = true
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    
                    if showSymptomButtons && viewModel.messages.count == 1 {
                        SymptomButtons(viewModel: viewModel, onSelection: {
                            showSymptomButtons = false
                        })
                    }
                }
                .padding()
                .onChange(of: viewModel.messages) { _ in
                    scrollToBottom(proxy: proxy)
                }
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .patient {
                Spacer()
                Text(message.content)
                    .padding()
                    .background(Color(red: 0.43, green: 0.34, blue: 0.99))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                if message.isDepartment {
                    DepartmentCard(department: message.department ?? "Unknown")
                } else if message.isDoctorList {
                    if let doctors = message.doctors, !doctors.isEmpty {
                        DoctorListCard(doctors: doctors)
                    } else {
                        Text(message.content)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                } else {
                    Text(message.content)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                Spacer()
            }
        }
        .padding(.horizontal, 8)
    }
}

private struct DepartmentCard: View {
    let department: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName(for: department))
                    .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                    .font(.title2)
                Text(department)
                    .font(.headline)
                    .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                Spacer()
            }
            Text("Recommended Department")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func iconName(for specialty: String) -> String {
        switch specialty {
        case "Cardiology": return "heart.fill"
        case "Orthopedics": return "figure.walk"
        case "Neurology": return "brain.head.profile"
        case "Gynecology": return "person.crop.circle.fill"
        case "Surgery": return "scissors"
        case "Dermatology": return "hand.raised.fill"
        case "Endocrinology": return "chart.bar.fill"
        case "ENT": return "ear.fill"
        case "Oncology": return "waveform.path.ecg"
        case "Psychiatry": return "brain.fill"
        case "Urology": return "kidneys"
        case "Pediatrics": return "figure.2.and.child.holdinghands"
        default: return "stethoscope"
        }
    }
}

private struct DoctorListCard: View {
    let doctors: [Doctor2]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Doctors")
                .font(.headline)
                .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
            
            ForEach(doctors) { doctor in
                DoctorCard(doctor: doctor)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DoctorCard: View {
    let doctor: Doctor2
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Dr. \(doctor.doctor_name)")
                .font(.subheadline.bold())
                .foregroundColor(.black)
            
            Text("\(doctor.department), \(doctor.doctor_experience ?? 0) yrs")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("Fee: \(doctor.consultationFee ?? 0)")
                .font(.caption)
                .foregroundColor(.gray)
            
            if let email = doctor.email {
                Text("Email: \(email)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if let phone = doctor.phoneNo {
                Text("Phone: \(phone)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct SymptomButtons: View {
    @ObservedObject var viewModel: ChatViewModel
    var onSelection: () -> Void
    
    let symptoms = ["Fever", "Cough", "Headache", "Sore Throat", "Dizziness"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(symptoms, id: \.self) { symptom in
                    Button(action: {
                        viewModel.inputText = "I have a \(symptom.lowercased())"
                        Task { await viewModel.sendMessage() }
                        onSelection()
                    }) {
                        Text(symptom)
                            .font(.subheadline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.1))
                            .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.99))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color(red: 0.43, green: 0.34, blue: 0.99).opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct InputView: View {
    @ObservedObject var viewModel: ChatViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Describe your symptoms...", text: $viewModel.inputText)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            Button(action: {
                Task { await viewModel.sendMessage() }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .tint(Color(red: 0.43, green: 0.34, blue: 0.99))
                } else {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(12)
            .background(Color(red: 0.43, green: 0.34, blue: 0.99))
            .clipShape(Circle())
            .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .top
        )
    }
}
