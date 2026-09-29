//
//  ProfileScreen.swift
//  DriveNow
//
//  Created by STUDENT on 9/17/25.
//

import SwiftUI
import PhotosUI

struct ProfileScreen: View {
    // MARK: - State Variables
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var profileImage: Image? = nil // Changed to optional to handle default state
    @State private var hasCustomProfileImage: Bool = false // Track if user has set a custom image

    // State to control the log-out alert dialog
    @State private var showLogoutAlert = false

    // Logout loading animation states
    @State private var showLogoutLoading = false
    @State private var isLoading = false
    @State private var scale: Double = 1.0

    // Use AuthViewModel from environment instead of a binding
    @EnvironmentObject var authViewModel: AuthViewModel

    // Key for UserDefaults
    private let profileImageKey = "profileImage"
    private let hasCustomImageKey = "hasCustomProfileImage"

    // New state variable to store the selected payment method
    @State private var selectedPaymentMethod: PaymentMethodScreen.PaymentMethod = .cash

    // State variable to control navigation to LoginSignUpScreen
    @State private var navigateToLoginSignUp = false

    // Shared user profile manager for displaying updated info from settings
    @StateObject private var userProfileManager = UserProfileManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background
                Color(red: 0.03, green: 0.11, blue: 0.26)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // MARK: - Navigation Bar Title
                    Text("Profile")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 50)
                        .padding(.bottom, 20)

                    // MARK: - Profile Header
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .top) {
                            // Display either custom profile image or default person icon
                            Group {
                                if let profileImage = profileImage {
                                    profileImage
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    // Default anonymous person icon
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            .shadow(radius: 10)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(userProfileManager.fullName)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                Text(userProfileManager.email)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 10)
                            .padding(.leading, 10)

                            Spacer()
                        }

                        // MARK: - Change Profile Photo Button (Functional)
                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Text(hasCustomProfileImage ? "Change Profile Photo" : "Add Profile Photo")
                                .font(.caption)
                                .foregroundColor(Color(red: 0.25, green: 0.45, blue: 1.0))
                                .padding(.top, 5)
                        }
                        .onChange(of: selectedItem) { oldValue, newItem in
                            guard let newItem = newItem else { return }
                            Task {
                                if let data = try? await newItem.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                                    // Update profile image
                                    self.profileImage = Image(uiImage: uiImage)
                                    self.hasCustomProfileImage = true

                                    // Save the image data and flag to UserDefaults
                                    UserDefaults.standard.set(data, forKey: profileImageKey)
                                    UserDefaults.standard.set(true, forKey: hasCustomImageKey)
                                }
                            }
                        }

                        Text("Joined: \(userProfileManager.joinedDate)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)

                    // MARK: - Settings and Payment Buttons
                    VStack(spacing: 1) {
                        // NavigationLink for Settings Button
                        NavigationLink(destination: SettingsScreen()) {
                            ProfileButton(icon: "gear", text: "Settings")
                        }

                        // NavigationLink for Payment Method Button with default values
                        NavigationLink(destination: PaymentMethodScreen(
                            selectedPaymentMethod: $selectedPaymentMethod,
                            amount: "₱0",
                            carName: "Profile Settings"
                        )) {
                            ProfileButton(icon: "creditcard", text: "Payment Method")
                        }

                        // NavigationLink for Security and Privacy Button
                        NavigationLink(destination: SecurityPrivacyScreen()) {
                            ProfileButton(icon: "lock.shield", text: "Security and Privacy")
                        }

                        // NavigationLink for Account Settings Button
                        NavigationLink(destination: AccountSettingsScreen()) {
                            ProfileButton(icon: "person.circle", text: "Account Settings")
                        }
                    }
                    .padding(.horizontal, 20)
                    .opacity(0.7)

                    // MARK: - Logout Button
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            Text("Log out")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .alert(isPresented: $showLogoutAlert) {
                        Alert(
                            title: Text("Log Out"),
                            message: Text("Are you sure you want to log out?"),
                            primaryButton: .destructive(Text("Yes")) {
                                // Start logout loading animation
                                showLogoutLoading = true
                            },
                            secondaryButton: .cancel(Text("No"))
                        )
                    }

                    Spacer()

                    // MARK: - Bottom Tab Bar with NavigationLinks
                    HStack(alignment: .center) {
                        // NavigationLink for Home Button
                        NavigationLink(destination: HomeTab()) {
                            ProfileTabItemView(imageName: "house.fill", title: "Home", isSelected: false)
                        }

                        // NavigationLink for My Rentals Button
                        NavigationLink(destination: MyRentalsScreen()) {
                            ProfileTabItemView(imageName: "list.bullet.rectangle.portrait.fill", title: "My Rentals", isSelected: false)
                        }

                        // Profile Tab (Current Screen)
                        ProfileTabItemView(imageName: "person.fill", title: "Profile", isSelected: true)
                    }
                    .padding(.vertical, 10)
                    .background(Color(red: 0.03, green: 0.11, blue: 0.26))
                    .cornerRadius(20)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }

                // MARK: - Logout Loading Overlay
                if showLogoutLoading {
                    ZStack {
                        // Semi-transparent background
                        Color.black.opacity(0.8)
                            .edgesIgnoringSafeArea(.all)

                        VStack(spacing: 30) {
                            // Logo in the center
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .scaleEffect(scale)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: scale)

                            // Loading text
                            Text("Logging out...")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)

                            // Loading animation - rotating circles
                            HStack(spacing: 10) {
                                ForEach(0..<3) { index in
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 12, height: 12)
                                        .scaleEffect(isLoading ? 1.0 : 0.5)
                                        .animation(
                                            .easeInOut(duration: 0.6)
                                            .repeatForever()
                                            .delay(Double(index) * 0.2),
                                            value: isLoading
                                        )
                                }
                            }
                        }
                    }
                    .onAppear {
                        // Start animations
                        isLoading = true
                        scale = 1.2

                        // After animation completes, logout and navigate
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            do {
                                try authViewModel.signOut()
                            } catch {
                                // ignore sign out error for now
                            }
                            navigateToLoginSignUp = true
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $navigateToLoginSignUp) {
                LoginSignUpScreen()
            }
            .onAppear {
                loadProfileImage()
            }
        }
    }

    // MARK: - Profile Image Loading
    private func loadProfileImage() {
        // Check if user has a custom profile image
        hasCustomProfileImage = UserDefaults.standard.bool(forKey: hasCustomImageKey)

        if hasCustomProfileImage {
            // Load custom image if it exists
            if let imageData = UserDefaults.standard.data(forKey: profileImageKey),
               let uiImage = UIImage(data: imageData) {
                self.profileImage = Image(uiImage: uiImage)
            } else {
                // If flag is true but no image data, reset to default
                hasCustomProfileImage = false
                UserDefaults.standard.set(false, forKey: hasCustomImageKey)
                self.profileImage = nil
            }
        } else {
            // Use default person icon for new accounts
            self.profileImage = nil
        }
    }
}

// MARK: - Profile Button Subview
struct ProfileButton: View {
    var icon: String
    var text: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0.03, green: 0.11, blue: 0.26))
            Text(text)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(red: 0.03, green: 0.11, blue: 0.26))
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

// MARK: - Tab Bar Item View (Corrected for consistent UI)
struct ProfileTabItemView: View {
    let imageName: String
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack {
            Image(systemName: imageName)
                .font(.system(size: 24))
                .foregroundColor(isSelected ? .blue : .white)
            Text(title)
                .font(.caption) // Corrected from .caption2
                .foregroundColor(isSelected ? .blue : .white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5) // Added to match HomeTab
    }
}

// MARK: - Preview Provider
struct ProfileScreen_Previews: PreviewProvider {
    static var previews: some View {
        ProfileScreen()
            .environmentObject(AuthViewModel.preview)
    }
}
