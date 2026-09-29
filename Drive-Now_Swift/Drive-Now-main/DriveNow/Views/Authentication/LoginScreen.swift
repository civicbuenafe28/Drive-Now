//
//  LoginScreen.swift
//  DriveNow
//
//  Created by STUDENT on 8/27/25.
//

import SwiftUI

struct LoginScreen: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible: Bool = false
    @State private var errorMessage: String?

    @Environment(\.dismiss) var dismiss

    @AppStorage("savedEmail") var savedEmail = ""

    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var navigateToLoading = false
    @State private var navigateToSignUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.03, green: 0.11, blue: 0.26)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    Image("logoonly-white")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .padding(.top, 50)

                    Text("Log In")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 30)

                    VStack(spacing: 15) {
                        TextField("Email", text: $email)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .padding(.horizontal, 20)
                            .disableAutocorrection(true)

                        HStack {
                            if isPasswordVisible {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                        
                        // Error message appears right after input fields
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.top, 5)
                        }
                    }

                    VStack(spacing: 15) {
                        Button(action: {
                            // Post notification that login has started
                            NotificationCenter.default.post(name: NSNotification.Name("LoginStarted"), object: nil)
                            
                            // Use Firebase Auth via AuthViewModel to sign in
                            Task {
                                do {
                                    try await authViewModel.signIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)

                                    await MainActor.run {
                                        // Load the current user's profile data
                                        UserProfileManager.shared.loadCurrentUserData()

                                        // Load favorites for the current user account
                                        FavoritesManager.shared.reloadFavoritesForCurrentUser()

                                        // Load purchase history for the current user account
                                        PurchaseHistoryManager.shared.reloadPurchaseHistoryForCurrentUser()

                                        navigateToLoading = true
                                    }
                                } catch {
                                    await MainActor.run {
                                        // Handle specific Firebase Auth errors
                                        if let authError = error as NSError? {
                                            let lower = authError.localizedDescription.lowercased()
                                            // Handle malformed or expired credential messages
                                            if lower.contains("malformed") || lower.contains("expired") {
                                                errorMessage = "Credentials are invalid or have expired. Please try logging in again."
                                            } else {
                                                switch authError.code {
                                                case 17009: // FIRAuthErrorCodeWrongPassword
                                                    errorMessage = "Incorrect Email or Password"
                                                case 17011: // FIRAuthErrorCodeUserNotFound
                                                    errorMessage = "Incorrect Email or Password"
                                                case 17008: // FIRAuthErrorCodeInvalidEmail
                                                    errorMessage = "Please enter a valid email address"
                                                case 17010: // FIRAuthErrorCodeUserDisabled
                                                    errorMessage = "This account has been disabled. Please contact support"
                                                case 17020: // FIRAuthErrorCodeNetworkError
                                                    errorMessage = "Network error. Please check your internet connection and try again"
                                                case 17999: // FIRAuthErrorCodeInternalError
                                                    errorMessage = "An internal error occurred. Please try again later"
                                                case 17012: // FIRAuthErrorCodeInvalidCredential
                                                    errorMessage = "Incorrect Email or Password"
                                                case 17017: // FIRAuthErrorCodeTooManyRequests
                                                    errorMessage = "Too many failed attempts. Please try again later"
                                                default:
                                                    errorMessage = "Login failed: \(error.localizedDescription)"
                                                }
                                            }
                                        } else {
                                            errorMessage = "Login failed: \(error.localizedDescription)"
                                        }
                                    }
                                }
                            }
                        }) {
                            Text("Log In")
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
                            Text("Go Back")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(red: 0.03, green: 0.11, blue: 0.26))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.85, green: 0.85, blue: 0.85))
                                .cornerRadius(15)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 30)

                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.white)
                        Button(action: {
                            navigateToSignUp = true
                        }) {
                            Text("Sign Up")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 50)

                }
                .navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $navigateToLoading) {
                LoginLoadingScreen()
            }
            .navigationDestination(isPresented: $navigateToSignUp) {
                SignUpScreen()
            }
        }
    }
}

#Preview {
    LoginScreen()
        .environmentObject(AuthViewModel.preview)
}
