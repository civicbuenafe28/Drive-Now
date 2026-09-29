//
//  AccountSettingsScreen.swift
//  DriveNow
//
//  Created by STUDENT on 10/5/25.
//

import SwiftUI
import FirebaseAuth

struct AccountSettingsScreen: View {
    // MARK: - State Variables
    @State private var showDeleteConfirmation: Bool = false
    @State private var passwordInput: String = ""
    @State private var showPasswordField: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var accountDeleted: Bool = false
    @State private var showPasswordError: Bool = false // New state for password error
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var navigateToLoginSignUp: Bool = false

    // Reference to UserProfileManager for local cleanup
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

                    Text("Account Settings")
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

                // MARK: - Account Actions Section
                VStack(alignment: .leading, spacing: 30) {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Danger Zone")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)

                        Text("Once you delete your account, there is no going back. Please be certain.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)

                        // Delete Account Button
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Delete Account")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                    }
                }

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $navigateToLoginSignUp) {
            LoginSignUpScreen()
        }
        .sheet(isPresented: $showDeleteConfirmation) {
            DeleteAccountConfirmationSheet(
                passwordInput: $passwordInput,
                showPasswordField: $showPasswordField,
                onConfirm: {
                    Task {
                        await performAccountDeletion()
                    }
                },
                onCancel: {
                    showDeleteConfirmation = false
                    passwordInput = ""
                    showPasswordField = false
                },
                showPasswordError: $showPasswordError // Pass the new state variable
            )
        }
        .alert(isPresented: $showAlert) {
            if accountDeleted {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("Log out")) {
                        // Send notification to ContentView to show LoginSignUpScreen directly
                        NotificationCenter.default.post(name: NSNotification.Name("AccountDeleted"), object: nil)
                        // Ensure authViewModel reflects signed-out state (AuthViewModel will update when account is deleted)
                        navigateToLoginSignUp = true
                    }
                )
            } else {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // MARK: - Delete Account Logic (reauthenticate via Firebase)
    private func performAccountDeletion() async {
        // Ensure user is signed in
        guard let firebaseUser = Auth.auth().currentUser else {
            await MainActor.run {
                showError(title: "No Signed-in User", message: "No authenticated user was found. Please log in again.")
            }
            return
        }

        // Ensure password input is present
        if passwordInput.isEmpty {
            await MainActor.run {
                showPasswordError = true
            }
            return
        }

        // Create credential using the user's email and the provided password
        // Ensure we have a valid email to build the credential (avoid malformed credential)
        guard let emailForReauth = (firebaseUser.email ?? userManager.currentUserEmail)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !emailForReauth.isEmpty else {
            await MainActor.run {
                showError(title: "Reauthentication Failed", message: "We couldn't determine your email address for reauthentication. Please sign in again from the login screen and try deleting your account.")
            }
            return
        }
        let credential = EmailAuthProvider.credential(withEmail: emailForReauth, password: passwordInput)

        // Reauthenticate
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                firebaseUser.reauthenticate(with: credential) { _, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
        } catch {
            await MainActor.run {
                // Default: handle wrong/invalid/expired credential with inline password error in the sheet
                if let authErr = error as NSError? {
                    let lower = authErr.localizedDescription.lowercased()

                    // Treat these cases as 'wrong password' so we keep the sheet open and show inline error
                    if authErr.code == 17009 || authErr.code == 17012 || lower.contains("wrong password") || lower.contains("malformed") || lower.contains("expired") {
                        showPasswordError = true
                        // Clear the password field so the user re-enters it
                        passwordInput = ""
                    }
                    // User not found and other conditions should show alerts
                    else if authErr.code == 17011 {
                        showError(title: "Account Error", message: "User account not found. Please log in again.")
                    } else if authErr.code == 17008 {
                        showError(title: "Invalid Email", message: "The email address is invalid.")
                    } else if authErr.code == 17020 {
                        showError(title: "Network Error", message: "Please check your internet connection and try again.")
                    } else if authErr.code == 17017 {
                        showError(title: "Too Many Attempts", message: "Too many failed attempts. Please try again later.")
                    } else {
                        // Other errors: show alert with server message
                        showError(title: "Reauthentication Failed", message: authErr.localizedDescription)
                    }
                } else {
                    // Unknown error: treat as wrong password for UX
                    showPasswordError = true
                    passwordInput = ""
                }
            }
            return
        }

        // At this point, reauthentication succeeded. Proceed to delete local data first.
        userManager.deleteAccount()

        // Then delete Firebase account
        do {
            try await authViewModel.deleteAccount()
        } catch {
            await MainActor.run {
                showError(title: "Deletion Failed", message: "Failed to delete account on server: \(error.localizedDescription). Local data was removed.")
            }
            return
        }

        // Success
        await MainActor.run {
            accountDeleted = true
            showSuccess(title: "Account Deleted", message: "Your account has been permanently deleted. You will now be logged out.")
        }
    }

    private func showError(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
        showDeleteConfirmation = false
        passwordInput = ""
        showPasswordField = false
    }

    private func showSuccess(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showDeleteConfirmation = false
        passwordInput = ""
        showPasswordField = false

        // Add a small delay to ensure the sheet dismisses before showing the alert
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showAlert = true
        }
    }
}

// MARK: - Delete Account Confirmation Sheet
struct DeleteAccountConfirmationSheet: View {
    @Binding var passwordInput: String
    @Binding var showPasswordField: Bool
    var onConfirm: () -> Void
    var onCancel: () -> Void
    @Binding var showPasswordError: Bool // Binding for password error state

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 15) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)

                Text("Delete Account")
                    .font(.title)
                    .fontWeight(.bold)

                Text("This action cannot be undone. All your data will be permanently deleted.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
            .padding()

            if !showPasswordField {
                Button(action: {
                    showPasswordField = true
                }) {
                    Text("I understand, delete my account")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 15) {
                    Text("Enter your password to confirm deletion:")
                        .font(.body)
                        .fontWeight(.medium)

                    SecureField("Current Password", text: $passwordInput)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    // Password error message
                    if showPasswordError {
                        Text("The password you entered is incorrect.")
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.top, 5)
                    }

                    HStack(spacing: 15) {
                        Button("Cancel") {
                            onCancel()
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)

                        Button("Delete Account") {
                            // Validate password presence before confirming deletion
                            if passwordInput.isEmpty {
                                showPasswordError = true
                            } else {
                                showPasswordError = false
                                onConfirm()
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(passwordInput.isEmpty ? Color.gray : Color.red)
                        .cornerRadius(10)
                        .disabled(passwordInput.isEmpty)
                    }
                }
                .padding(.horizontal, 20)
            }

            if !showPasswordField {
                Button("Cancel") {
                    onCancel()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal, 20)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .frame(maxWidth: 400, maxHeight: 500)
    }
}

// MARK: - Preview Provider
struct AccountSettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        AccountSettingsScreen()
            .environmentObject(AuthViewModel.preview)
    }
}
