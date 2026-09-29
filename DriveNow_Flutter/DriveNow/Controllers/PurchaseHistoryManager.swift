//
//  PurchaseHistoryManager.swift
//  DriveNow
//
//  Created by STUDENT on 10/8/25.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Purchase History Model
struct PurchaseHistoryItem: Identifiable, Codable {
    let id: UUID
    let paymentMethod: String
    let date: Date
    let carName: String
    let totalAmount: String
    let transactionID: String
    
    init(paymentMethod: String, date: Date, carName: String, totalAmount: String, transactionID: String) {
        self.id = UUID()
        self.paymentMethod = paymentMethod
        self.date = date
        self.carName = carName
        self.totalAmount = totalAmount
        self.transactionID = transactionID
    }
}

// MARK: - Purchase History Manager
class PurchaseHistoryManager: ObservableObject {
    @Published var purchaseHistory: [PurchaseHistoryItem] = []
    private let db = Firestore.firestore()
    
    static let shared = PurchaseHistoryManager()
    
    private init() {
        loadPurchaseHistory()
    }
    
    // Get the current user's unique key for storing purchase history
    private var currentUserKey: String {
        let currentUserEmail = UserProfileManager.shared.currentUserEmail
        if currentUserEmail.isEmpty {
            // Fallback to a default key if no user is logged in
            return "PurchaseHistory_default"
        }
        return "PurchaseHistory_\(currentUserEmail)"
    }
    
    func addPurchase(paymentMethod: String, carName: String, totalAmount: String) {
        let newPurchase = PurchaseHistoryItem(
            paymentMethod: paymentMethod,
            date: Date(),
            carName: carName,
            totalAmount: totalAmount,
            transactionID: generateTransactionID(for: paymentMethod)
        )
        purchaseHistory.insert(newPurchase, at: 0) // Add to beginning for newest first
        savePurchaseHistory()
        saveToFirestore(newPurchase) // Sync to Firestore
    }
    
    private func generateTransactionID(for paymentMethod: String) -> String {
        let prefix = paymentMethod == "Credit Card" ? "CC" : paymentMethod == "GCash" ? "GC" : "CS"
        let randomNumber = Int.random(in: 100000...999999)
        return "\(prefix)\(randomNumber)"
    }
    
    private func savePurchaseHistory() {
        if let encoded = try? JSONEncoder().encode(purchaseHistory) {
            UserDefaults.standard.set(encoded, forKey: currentUserKey)
        }
    }
    
    private func loadPurchaseHistory() {
        if let data = UserDefaults.standard.data(forKey: currentUserKey),
           let decoded = try? JSONDecoder().decode([PurchaseHistoryItem].self, from: data) {
            purchaseHistory = decoded
        } else {
            // Initialize with empty array for new users
            purchaseHistory = []
        }
    }
    
    // Function to reload purchase history when user changes (e.g., login/logout)
    func reloadPurchaseHistoryForCurrentUser() {
        loadPurchaseHistory()
    }
    
    // Function to clear purchase history for current user (useful for account deletion)
    func clearPurchaseHistory() {
        purchaseHistory = []
        UserDefaults.standard.removeObject(forKey: currentUserKey)
    }
    
    // Function to get purchase history for a specific user (admin function)
    func getPurchaseHistoryForUser(email: String) -> [PurchaseHistoryItem] {
        let userKey = "PurchaseHistory_\(email)"
        if let data = UserDefaults.standard.data(forKey: userKey),
           let decoded = try? JSONDecoder().decode([PurchaseHistoryItem].self, from: data) {
            return decoded
        }
        return []
    }
    
    // MARK: - Firestore Sync Methods
    
    /// Save a purchase to Firestore
    private func saveToFirestore(_ purchase: PurchaseHistoryItem) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user, skipping Firestore sync")
            return
        }
        
        let purchaseData: [String: Any] = [
            "id": purchase.id.uuidString,
            "paymentMethod": purchase.paymentMethod,
            "date": Timestamp(date: purchase.date),
            "carName": purchase.carName,
            "totalAmount": purchase.totalAmount,
            "transactionID": purchase.transactionID
        ]
        
        db.collection("users").document(userId).collection("purchaseHistory").document(purchase.id.uuidString).setData(purchaseData) { error in
            if let error = error {
                print("Error saving purchase to Firestore: \(error.localizedDescription)")
            } else {
                print("Purchase successfully saved to Firestore")
            }
        }
    }
    
    /// Load purchase history from Firestore for current user
    func loadFromFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user, loading from UserDefaults only")
            loadPurchaseHistory()
            return
        }
        
        db.collection("users").document(userId).collection("purchaseHistory")
            .order(by: "date", descending: true)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error loading purchase history from Firestore: \(error.localizedDescription)")
                    self?.loadPurchaseHistory() // Fallback to UserDefaults
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No purchase history found in Firestore, loading from UserDefaults")
                    self?.loadPurchaseHistory()
                    return
                }
                
                let purchases = documents.compactMap { doc -> PurchaseHistoryItem? in
                    let data = doc.data()
                    guard let idString = data["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let paymentMethod = data["paymentMethod"] as? String,
                          let timestamp = data["date"] as? Timestamp,
                          let carName = data["carName"] as? String,
                          let totalAmount = data["totalAmount"] as? String,
                          let transactionID = data["transactionID"] as? String else {
                        return nil
                    }
                    
                    return PurchaseHistoryItem(
                        paymentMethod: paymentMethod,
                        date: timestamp.dateValue(),
                        carName: carName,
                        totalAmount: totalAmount,
                        transactionID: transactionID
                    )
                }
                
                DispatchQueue.main.async {
                    self?.purchaseHistory = purchases
                    self?.savePurchaseHistory() // Save to UserDefaults as backup
                    print("Purchase history loaded from Firestore: \(purchases.count) items")
                }
            }
    }
}
