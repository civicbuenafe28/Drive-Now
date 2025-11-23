//
//  UserProfileManager.swift
//  DriveNow
//
//  Created by STUDENT on 10/2/25.
//

import Foundation
import SwiftUI

// MARK: - Shared User Profile Manager
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    @Published var fullName: String = "Civic Buenafe" {
        didSet {
            UserDefaults.standard.set(fullName, forKey: "userFullName")
        }
    }
    
    @Published var email: String = "carlvictor328@gmail.com" {
        didSet {
            UserDefaults.standard.set(email, forKey: "userEmail")
        }
    }
    
    @Published var phoneNumber: String = "" {
        didSet {
            UserDefaults.standard.set(phoneNumber, forKey: "userPhoneNumber")
        }
    }
    
    @Published var licenseInfo: String = "" {
        didSet {
            UserDefaults.standard.set(licenseInfo, forKey: "userLicenseInfo")
        }
    }
    
    @Published var joinedDate: String = "January 1, 2025" {
        didSet {
            UserDefaults.standard.set(joinedDate, forKey: "userJoinedDate")
        }
    }

    // Password management for the current signed-in user
    var currentUserPassword: String {
        get {
            return UserDefaults.standard.string(forKey: "savedPassword") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "savedPassword")
        }
    }
    
    var currentUserEmail: String {
        get {
            return UserDefaults.standard.string(forKey: "savedEmail") ?? ""
        }
    }
    
    private init() {
        loadUserData()
    }
    
    private func loadUserData() {
        // Load data from the currently logged-in user's saved information
        let savedEmail = UserDefaults.standard.string(forKey: "savedEmail") ?? ""
        let savedFullName = UserDefaults.standard.string(forKey: "savedFullName") ?? ""
        let savedJoinedDate = UserDefaults.standard.string(forKey: "savedJoinedDate") ?? ""
        
        // Update the published properties with the actual logged-in user's data
        if !savedEmail.isEmpty {
            email = savedEmail
        }
        if !savedFullName.isEmpty {
            fullName = savedFullName
        }
        if !savedJoinedDate.isEmpty {
            joinedDate = savedJoinedDate
        }
        
        // Load other profile data or default to blank for new accounts
        phoneNumber = UserDefaults.standard.string(forKey: "userPhoneNumber") ?? ""
        licenseInfo = UserDefaults.standard.string(forKey: "userLicenseInfo") ?? ""
    }
    
    // Add a function to update user data when user logs in
    func loadCurrentUserData() {
        loadUserData()
    }
    
    func updateFullName(_ newName: String) {
        fullName = newName
    }
    
    func updateEmail(_ newEmail: String) {
        email = newEmail
    }
    
    func updatePhoneNumber(_ newPhone: String) {
        phoneNumber = newPhone
    }
    
    func updateLicenseInfo(_ newLicense: String) {
        licenseInfo = newLicense
    }
    
    func updateJoinedDate(_ newDate: String) {
        joinedDate = newDate
    }
    
    // MARK: - Settings Save Functions
    func saveProfileSettingsToLogin() {
        // Update the login credentials with the new profile information
        // This ensures that when the user logs in next time, the updated info is reflected
        UserDefaults.standard.set(email, forKey: "savedEmail")
        UserDefaults.standard.set(fullName, forKey: "savedFullName")
        
        // Also update the user profile keys including phone number and license info
        UserDefaults.standard.set(fullName, forKey: "userFullName")
        UserDefaults.standard.set(email, forKey: "userEmail")
        UserDefaults.standard.set(phoneNumber, forKey: "userPhoneNumber")
        UserDefaults.standard.set(licenseInfo, forKey: "userLicenseInfo")
    }
    
    // MARK: - Account Deletion Functions
    func deleteAccount() {
        // Get the current user's email before clearing it (for cleanup purposes)
        let userEmailForCleanup = currentUserEmail
        
        // Clear all user-specific data from the managers BEFORE clearing profile data
        if !userEmailForCleanup.isEmpty {
            // Clear favorites for this specific user
            let favoritesKey = "FavoriteCars_\(userEmailForCleanup)"
            UserDefaults.standard.removeObject(forKey: favoritesKey)
            
            // Clear purchase history for this specific user
            let purchaseHistoryKey = "PurchaseHistory_\(userEmailForCleanup)"
            UserDefaults.standard.removeObject(forKey: purchaseHistoryKey)
            
            // Clear rental bookings for this specific user
            let rentalBookingsKey = "RentalBookings_\(userEmailForCleanup)"
            UserDefaults.standard.removeObject(forKey: rentalBookingsKey)
        }
        
        // Clear all user profile data from UserDefaults
        UserDefaults.standard.removeObject(forKey: "savedEmail")
        UserDefaults.standard.removeObject(forKey: "savedPassword")
        UserDefaults.standard.removeObject(forKey: "savedFullName")
        UserDefaults.standard.removeObject(forKey: "savedJoinedDate")
        UserDefaults.standard.removeObject(forKey: "userFullName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userPhoneNumber")
        UserDefaults.standard.removeObject(forKey: "userLicenseInfo")
        UserDefaults.standard.removeObject(forKey: "userJoinedDate")
        UserDefaults.standard.removeObject(forKey: "profileImage")
        UserDefaults.standard.set(false, forKey: "hasCustomProfileImage")
        
        // Reset the published properties to default values
        fullName = "Civic Buenafe"
        email = "carlvictor328@gmail.com"
        phoneNumber = ""
        licenseInfo = ""
        joinedDate = "January 1, 2025"
        
        // Clear the managers' in-memory data immediately
        DispatchQueue.main.async {
            FavoritesManager.shared.reloadFavoritesForCurrentUser()
            PurchaseHistoryManager.shared.reloadPurchaseHistoryForCurrentUser()
            RentalManager.shared.reloadBookingsForCurrentUser()
        }
    }
    
    // MARK: - Password Management Functions
    // Note: Firebase Authentication handles actual password storage and validation.
    // These methods are kept for backwards compatibility but should not be used for real authentication.
    
    @available(*, deprecated, message: "Use Firebase Authentication for password validation")
    func validateCurrentPassword(_ password: String) -> Bool {
        return password == currentUserPassword
    }
    
    @available(*, deprecated, message: "Use Firebase Authentication updatePassword method instead")
    func updatePassword(_ newPassword: String) -> Bool {
        // Validate password strength
        guard isValidPassword(newPassword) else { return false }
        
        // Update the stored password
        currentUserPassword = newPassword
        return true
    }
    
    /// Validates password strength requirements
    /// - Parameter password: The password to validate
    /// - Returns: true if password meets all requirements (8+ chars, uppercase, lowercase, number)
    func isValidPassword(_ password: String) -> Bool {
        let hasMinimumLength = password.count >= 8
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumbers = password.range(of: "[0-9]", options: .regularExpression) != nil
        
        return hasMinimumLength && hasUppercase && hasLowercase && hasNumbers
    }
}
