//
//  AdminSettingsView.swift
//  Carehub
//
//  Created by Yash Gupta on 06/05/25.
//

import SwiftUI

struct AdminSettingsView: View {
    @State private var hospitalName = "City General Hospital"
    @State private var hospitalLogo: UIImage?
    @State private var showImagePicker = false
    @State private var notificationEnabled = true
    @State private var darkModeEnabled = false
    private let purpleColor = Color(red: 0.43, green: 0.34, blue: 0.99)
    private let gradientColors = [Color(red: 0.43, green: 0.34, blue: 0.99), Color(red: 0.55, green: 0.48, blue: 0.99)]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.94, green: 0.94, blue: 1.0)
                    .edgesIgnoringSafeArea(.all)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                        .padding(.horizontal, 20)
                    
                    Form {
                        Section(header: Text("Hospital Information")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)) {
                            TextField("Hospital Name", text: $hospitalName)
                            
                            Button {
                                showImagePicker = true
                            } label: {
                                HStack {
                                    Text("Hospital Logo")
                                    Spacer()
                                    if let logo = hospitalLogo {
                                        Image(uiImage: logo)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50)
                                    } else {
                                        Image(systemName: "photo")
                                            .foregroundColor(purpleColor)
                                    }
                                }
                            }
                        }
                        
                        Section(header: Text("Preferences")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)) {
                            Toggle("Enable Notifications", isOn: $notificationEnabled)
                            Toggle("Dark Mode", isOn: $darkModeEnabled)
                        }
                        
                        Section {
                            Button(role: .destructive) {
                                // Handle logout
                            } label: {
                                Text("Log Out")
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .background(Color.clear)
                }
                .padding(.top, 10)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $hospitalLogo)
            }
        }
    }
}
// ImagePicker.swift (for AdminSettingsView)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
    }
}

