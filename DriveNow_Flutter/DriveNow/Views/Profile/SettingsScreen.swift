//
//  SettingsScreen.swift
//  DriveNow
//
//  Created by STUDENT on 9/17/25.
//

import SwiftUI

struct SettingsScreen: View {
    // MARK: - State Variables
    @StateObject private var userProfileManager = UserProfileManager.shared
    
    @State private var isEditing: Bool = false // Tracks whether we are editing the text
    @State private var editingField: String = "" // Stores the field being edited
    @State private var newText: String = "" // Stores the new text entered in the dialog
    @State private var showSaveAlert: Bool = false // Show save confirmation alert
    
    // Environment object for navigation
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // MARK: - Background
            Color(red: 0.03, green: 0.11, blue: 0.26)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // MARK: - Navigation Bar
                HStack {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white)
                            .font(.system(size: 24, weight: .bold))
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    Text("Settings")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Empty view to balance the navigation bar layout
                    Image(systemName: "arrow.left")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.clear)
                        .padding(.trailing, 20)
                }
                .padding(.top, 50)
                .padding(.bottom, 20)
                
                // MARK: - User Info Fields
                VStack(spacing: 20) {
                    UserInfoField(label: "Full Name:", text: $userProfileManager.fullName, onEdit: {
                        self.startEditing(field: "Full Name", currentValue: userProfileManager.fullName)
                    })
                    UserInfoField(label: "Email Address:", text: $userProfileManager.email, onEdit: {
                        self.startEditing(field: "Email", currentValue: userProfileManager.email)
                    })
                    UserInfoField(label: "Phone Number:", text: $userProfileManager.phoneNumber, onEdit: {
                        self.startEditing(field: "Phone Number", currentValue: userProfileManager.phoneNumber)
                    })
                    UserInfoField(label: "License Info:", text: $userProfileManager.licenseInfo, onEdit: {
                        self.startEditing(field: "License Info", currentValue: userProfileManager.licenseInfo)
                    })
                    
                    // MARK: - Save Button
                    Button(action: {
                        saveProfileChanges()
                    }) {
                        Text("Save Changes")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $isEditing) {
            // EditFieldSheet View
            EditFieldSheet(field: $editingField, newText: $newText, saveAction: {
                saveEditing()
            }, discardAction: {
                discardEditing()
            })
        }
        .alert(isPresented: $showSaveAlert) {
            Alert(title: Text("Changes Saved"),
                  message: Text("Your profile changes have been saved successfully."),
                  dismissButton: .default(Text("OK")))
        }
    }
    
    // Function to start editing a field
    private func startEditing(field: String, currentValue: String) {
        self.editingField = field
        self.newText = currentValue
        self.isEditing = true
    }
    
    // Save the new value to the corresponding field
    private func saveEditing() {
        switch editingField {
        case "Full Name":
            userProfileManager.updateFullName(newText)
        case "Email":
            userProfileManager.updateEmail(newText)
        case "Phone Number":
            userProfileManager.updatePhoneNumber(newText)
        case "License Info":
            userProfileManager.updateLicenseInfo(newText)
        default:
            break
        }
        self.isEditing = false
    }
    
    // Discard the changes
    private func discardEditing() {
        self.isEditing = false
    }
    
    // MARK: - Save Profile Changes
    private func saveProfileChanges() {
        // Save the profile changes to both the profile data and login credentials
        userProfileManager.saveProfileSettingsToLogin()
        
        // Show the save confirmation alert
        showSaveAlert = true
    }
}

// MARK: - Edit Field Modal Sheet
struct EditFieldSheet: View {
    @Binding var field: String
    @Binding var newText: String
    var saveAction: () -> Void
    var discardAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit \(field)")
                .font(.title)
                .padding()
            
            TextField("Enter new value", text: $newText)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack {
                Button("Cancel") {
                    discardAction()
                }
                .foregroundColor(.red)
                .padding()
                
                Spacer()
                
                Button("Save") {
                    saveAction()
                }
                .foregroundColor(.blue)
                .padding()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .frame(maxWidth: 400, maxHeight: 250)
    }
}

// MARK: - User Info Field Subview
struct UserInfoField: View {
    var label: String
    @Binding var text: String
    var onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            HStack {
                TextField("", text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.03, green: 0.11, blue: 0.26))
                    .padding(.leading, 10)
                    .disabled(true) // Disable direct editing
                
                Spacer()
                
                Button(action: onEdit) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(Color(red: 0.03, green: 0.11, blue: 0.26))
                        .padding(.horizontal, 10)
                }
            }
            .frame(height: 40)
            .background(Color.white)
            .cornerRadius(8)
        }
    }
}

// MARK: - Preview Provider
struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsScreen()
    }
}
