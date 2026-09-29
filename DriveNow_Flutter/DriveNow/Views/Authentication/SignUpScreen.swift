//
//  SignUpScreen.swift
//  DriveNow
//
//  Created by STUDENT on 8/27/25.
//

import SwiftUI

struct SignUpScreen: View {
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var showAlert = false
    @State private var navigateToLogin = false
    @State private var errorMessage = ""
    @State private var showError = false

    @Environment(\.dismiss) var dismiss
    @AppStorage("savedEmail") var savedEmail = ""
    @AppStorage("savedFullName") var savedFullName = ""
    @AppStorage("savedJoinedDate") var savedJoinedDate = ""

    @EnvironmentObject var authViewModel: AuthViewModel

    // Validation function
    private func validateInput() -> Bool {
        if fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Please enter your full name"
            showError = true
            return false
        }

        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Please enter your email address"
            showError = true
            return false
        }

        if !isValidEmail(email) {
            errorMessage = "Please enter a valid email address"
            showError = true
            return false
        }

        if password.isEmpty {
            errorMessage = "Please enter a password"
            showError = true
            return false
        }

        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters long"
            showError = true
            return false
        }

        if confirmPassword.isEmpty {
            errorMessage = "Please confirm your password"
            showError = true
            return false
        }

        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            showError = true
            return false
        }

        return true
    }

    // Email validation function
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPred.evaluate(with: email)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.03, green: 0.11, blue: 0.26)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 30) {
                    Image("logoonly-white")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .padding(.top, 50)
                        .padding(.bottom, 20)

                    Text("Sign Up")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 20)

                    VStack(spacing: 15) {
                        TextField("Full Name", text: $fullName)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .padding(.horizontal, 20)

                        TextField("Email", text: $email)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .padding(.horizontal, 20)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.emailAddress)

                        ZStack(alignment: .trailing) {
                            Group {
                                if isPasswordVisible {
                                    TextField("Password", text: $password)
                                } else {
                                    SecureField("Password", text: $password)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .padding(.horizontal, 20)

                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 35)
                            }
                        }

                        ZStack(alignment: .trailing) {
                            Group {
                                if isConfirmPasswordVisible {
                                    TextField("Confirm Password", text: $confirmPassword)
                                } else {
                                    SecureField("Confirm Password", text: $confirmPassword)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .padding(.horizontal, 20)

                            Button(action: {
                                isConfirmPasswordVisible.toggle()
                            }) {
                                Image(systemName: isConfirmPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 35)
                            }
                        }
                    }

                    VStack(spacing: 15) {
                        Button(action: {
                            if validateInput() {
                                // Use Firebase signUp via AuthViewModel
                                Task {
                                    do {
                                        try await authViewModel.signUp(fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines), email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)

                                        // Save some non-sensitive profile data locally
                                        await MainActor.run {
                                            savedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                                            savedFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)

                                            // Save the current date as joined date
                                            let formatter = DateFormatter()
                                            formatter.dateStyle = .long
                                            savedJoinedDate = formatter.string(from: Date())

                                            // Clear profile image data for new account - start with default person icon
                                            UserDefaults.standard.removeObject(forKey: "profileImage")
                                            UserDefaults.standard.set(false, forKey: "hasCustomProfileImage")

                                            // Clear phone number and license info for new accounts - start with blank
                                            UserDefaults.standard.removeObject(forKey: "userPhoneNumber")
                                            UserDefaults.standard.removeObject(forKey: "userLicenseInfo")

                                            // Reload managers for the new user to ensure clean data
                                            FavoritesManager.shared.reloadFavoritesForCurrentUser()
                                            PurchaseHistoryManager.shared.reloadPurchaseHistoryForCurrentUser()
                                            RentalManager.shared.reloadBookingsForCurrentUser()
                                            UserProfileManager.shared.loadCurrentUserData()

                                            showAlert = true
                                        }
                                    } catch {
                                        await MainActor.run {
                                            // Handle specific Firebase Auth errors
                                            if let authError = error as NSError? {
                                                switch authError.code {
                                                case 17007: // FIRAuthErrorCodeEmailAlreadyInUse
                                                    errorMessage = "This email address is already in use. Please try logging in instead."
                                                case 17008: // FIRAuthErrorCodeInvalidEmail
                                                    errorMessage = "Please enter a valid email address."
                                                case 17026: // FIRAuthErrorCodeWeakPassword
                                                    errorMessage = "Password is too weak. Please choose a stronger password."
                                                case 17020: // FIRAuthErrorCodeNetworkError
                                                    errorMessage = "Network error. Please check your internet connection and try again."
                                                case 17999: // FIRAuthErrorCodeInternalError
                                                    errorMessage = "An internal error occurred. Please try again later."
                                                default:
                                                    errorMessage = "Sign up failed: \(error.localizedDescription)"
                                                }
                                            } else {
                                                errorMessage = "Sign up failed: \(error.localizedDescription)"
                                            }
                                            showError = true
                                        }
                                    }
                                }
                            }
                        }) {
                            Text("Sign Up")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.25, green: 0.45, blue: 1.0))
                                .cornerRadius(15)
                        }
                        .padding(.horizontal, 20)

                        Button(action: {
                            dismiss()
                        }) {
                            Text("Cancel")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(red: 0.03, green: 0.11, blue: 0.26))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.85, green: 0.85, blue: 0.85))
                                .cornerRadius(15)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)

                    Spacer()
                }
            }
            .navigationBarBackButtonHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Account Successfully Created"),
                    message: Text("Your account has been created successfully. Please log in with your credentials."),
                    dismissButton: .default(Text("OK")) {
                        navigateToLogin = true
                    }
                )
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginScreen()
            }
        }
    }
}

#Preview {
    SignUpScreen()
        .environmentObject(AuthViewModel.preview)
}
