//
//  SecurityPrivacyScreen.swift
//  DriveNow
//
//  Created by STUDENT on 10/4/25.
//

import SwiftUI
import FirebaseAuth

struct SecurityPrivacyScreen: View {
    // MARK: - State Variables
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showCurrentPassword: Bool = false
    @State private var showNewPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var isProcessing: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    // Reference to UserProfileManager for password management
    private let userManager = UserProfileManager.shared
    
    var body: some View {
        ZStack {
            // MARK: - Background
            Color(red: 0.03, green: 0.11, blue: 0.26)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // MARK: - Navigation Bar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Security & Privacy")
                        .font(.system(size: 27, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Empty space to balance the HStack
                    Color.clear
                        .frame(width: 24, height: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .padding(.bottom, 30)
                
                // MARK: - Change Password Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Change Password")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 15) {
                        // Current Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Password")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            HStack {
                                if showCurrentPassword {
                                    TextField("Enter current password", text: $currentPassword)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                } else {
                                    SecureField("Enter current password", text: $currentPassword)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                Button(action: {
                                    showCurrentPassword.toggle()
                                }) {
                                    Image(systemName: showCurrentPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        // New Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            HStack {
                                if showNewPassword {
                                    TextField("Enter new password", text: $newPassword)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                } else {
                                    SecureField("Enter new password", text: $newPassword)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                Button(action: {
                                    showNewPassword.toggle()
                                }) {
                                    Image(systemName: showNewPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm New Password")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            HStack {
                                if showConfirmPassword {
                                    TextField("Confirm new password", text: $confirmPassword)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                } else {
                                    SecureField("Confirm new password", text: $confirmPassword)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                Button(action: {
                                    showConfirmPassword.toggle()
                                }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Password Requirements
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Password Requirements:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("• At least 8 characters long")
                            Text("• Contains at least one uppercase letter")
                            Text("• Contains at least one lowercase letter")
                            Text("• Contains at least one number")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 10)
                    
                    // Change Password Button
                    Button(action: {
                        changePassword()
                    }) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Changing Password...")
                            } else {
                                Text("Change Password")
                            }
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isProcessing || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .disabled(isProcessing || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if alertTitle == "Success" {
                        // Clear password fields after successful change
                        currentPassword = ""
                        newPassword = ""
                        confirmPassword = ""
                    }
                }
            )
        }
    }
    
    // MARK: - Password Change Logic
    private func changePassword() {
        // Validate new password requirements first
        guard userManager.isValidPassword(newPassword) else {
            showError(title: "Invalid Password", message: "Please ensure your new password meets all requirements.")
            return
        }
        
        // Check if new passwords match
        guard newPassword == confirmPassword else {
            showError(title: "Password Mismatch", message: "New password and confirmation password do not match.")
            return
        }
        
        // Check if new password is different from current
        guard newPassword != currentPassword else {
            showError(title: "Same Password", message: "New password must be different from your current password.")
            return
        }
        
        // Get the current Firebase user
        guard let user = Auth.auth().currentUser else {
            showError(title: "Error", message: "No user is currently signed in. Please log in again.")
            return
        }
        
        guard let email = user.email else {
            showError(title: "Error", message: "Unable to retrieve user email. Please log in again.")
            return
        }
        
        isProcessing = true
        
        // Re-authenticate the user with their current password
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        user.reauthenticate(with: credential) { authResult, error in
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    // Handle re-authentication errors
                    let nsError = error as NSError
                    switch nsError.code {
                    case 17009: // Wrong password
                        self.showError(title: "Incorrect Password", message: "The current password you entered is incorrect.")
                    case 17020: // Network error
                        self.showError(title: "Network Error", message: "Please check your internet connection and try again.")
                    case 17017: // Too many requests
                        self.showError(title: "Too Many Attempts", message: "Too many failed attempts. Please try again later.")
                    default:
                        self.showError(title: "Authentication Error", message: "Failed to verify your current password. Please try again.")
                    }
                }
                return
            }
            
            // Now update the password
            user.updatePassword(to: self.newPassword) { error in
                DispatchQueue.main.async {
                    self.isProcessing = false
                    
                    if let error = error {
                        // Handle password update errors
                        let nsError = error as NSError
                        switch nsError.code {
                        case 17026: // Password too weak (though we already validated)
                            self.showError(title: "Weak Password", message: "The new password is too weak. Please choose a stronger password.")
                        case 17020: // Network error
                            self.showError(title: "Network Error", message: "Please check your internet connection and try again.")
                        case 17014: // Requires recent login
                            self.showError(title: "Session Expired", message: "For security reasons, please log out and log back in before changing your password.")
                        default:
                            self.showError(title: "Error", message: "Failed to update password: \(error.localizedDescription)")
                        }
                        return
                    }
                    
                    // Password successfully updated in Firebase
                    self.showSuccess(title: "Success", message: "Your password has been changed successfully. Please use your new password for future logins.")
                }
            }
        }
    }
    
    private func validatePassword(_ password: String) -> Bool {
        return userManager.isValidPassword(password)
    }
    
    private func showError(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    private func showSuccess(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Preview Provider
struct SecurityPrivacyScreen_Previews: PreviewProvider {
    static var previews: some View {
        SecurityPrivacyScreen()
    }
}
