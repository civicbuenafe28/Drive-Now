//
//  UserDataMonitor.swift
//  DriveNow
//
//  Created to monitor user data in Firebase Firestore
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

/// Monitor and sync user data from Firebase Firestore in real-time
class UserDataMonitor: ObservableObject {
    static let shared = UserDataMonitor()
    
    @Published var userBookings: [[String: Any]] = []
    @Published var userFavorites: [[String: Any]] = []
    @Published var userPurchaseHistory: [[String: Any]] = []
    @Published var isListening: Bool = false
    
    private var bookingsListener: ListenerRegistration?
    private var favoritesListener: ListenerRegistration?
    private var purchaseHistoryListener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    private init() {
        // Private initializer to enforce singleton pattern
    }
    
    deinit {
        stopListening()
    }
    
    /// Start listening to all user data in Firestore
    func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user, cannot start Firestore listeners")
            return
        }
        
        print("✅ Starting Firestore listeners for user: \(userId)")
        isListening = true
        
        // Listen to bookings
        bookingsListener = db.collection("users").document(userId).collection("bookings")
            .order(by: "bookingDate", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error listening to bookings: \(error.localizedDescription)")
                    return
                }
                
                self?.userBookings = snapshot?.documents.map { $0.data() } ?? []
                print("📊 Bookings updated: \(self?.userBookings.count ?? 0) items")
            }
        
        // Listen to favorites
        favoritesListener = db.collection("users").document(userId).collection("favorites")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error listening to favorites: \(error.localizedDescription)")
                    return
                }
                
                self?.userFavorites = snapshot?.documents.map { $0.data() } ?? []
                print("❤️ Favorites updated: \(self?.userFavorites.count ?? 0) items")
            }
        
        // Listen to purchase history
        purchaseHistoryListener = db.collection("users").document(userId).collection("purchaseHistory")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error listening to purchase history: \(error.localizedDescription)")
                    return
                }
                
                self?.userPurchaseHistory = snapshot?.documents.map { $0.data() } ?? []
                print("🛒 Purchase history updated: \(self?.userPurchaseHistory.count ?? 0) items")
            }
    }
    
    /// Stop all Firestore listeners
    func stopListening() {
        bookingsListener?.remove()
        favoritesListener?.remove()
        purchaseHistoryListener?.remove()
        
        bookingsListener = nil
        favoritesListener = nil
        purchaseHistoryListener = nil
        
        userBookings = []
        userFavorites = []
        userPurchaseHistory = []
        isListening = false
        
        print("🛑 Stopped all Firestore listeners")
    }
    
    /// Print current user data to console (for debugging/monitoring)
    func printUserData() {
        guard let userId = Auth.auth().currentUser?.uid,
              let userEmail = Auth.auth().currentUser?.email else {
            print("❌ No authenticated user")
            return
        }
        
        print("\n" + String(repeating: "=", count: 60))
        print("📱 USER DATA MONITOR")
        print(String(repeating: "=", count: 60))
        print("👤 User ID: \(userId)")
        print("📧 Email: \(userEmail)")
        print(String(repeating: "-", count: 60))
        
        print("\n🚗 BOOKINGS (\(userBookings.count) total):")
        for (index, booking) in userBookings.enumerated() {
            print("  \(index + 1). \(booking["carName"] ?? "Unknown") - \(booking["totalAmount"] ?? "0") PHP")
            print("     Location: \(booking["location"] ?? "N/A")")
            print("     Payment: \(booking["paymentMethod"] ?? "N/A")")
        }
        
        print("\n❤️ FAVORITES (\(userFavorites.count) total):")
        for (index, favorite) in userFavorites.enumerated() {
            if let cars = favorite["cars"] as? [[String: Any]] {
                print("  Favorite list \(index + 1): \(cars.count) cars")
                for (carIndex, car) in cars.enumerated() {
                    print("    \(carIndex + 1). \(car["name"] ?? "Unknown") - \(car["price"] ?? "N/A")")
                }
            }
        }
        
        print("\n🛒 PURCHASE HISTORY (\(userPurchaseHistory.count) total):")
        for (index, purchase) in userPurchaseHistory.enumerated() {
            print("  \(index + 1). \(purchase["carName"] ?? "Unknown") - \(purchase["totalAmount"] ?? "0") PHP")
            print("     Transaction: \(purchase["transactionID"] ?? "N/A")")
            print("     Method: \(purchase["paymentMethod"] ?? "N/A")")
        }
        
        print("\n" + String(repeating: "=", count: 60) + "\n")
    }
}
