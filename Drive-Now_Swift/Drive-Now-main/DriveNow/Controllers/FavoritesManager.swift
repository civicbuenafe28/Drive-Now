//
//  FavoritesManager.swift
//  DriveNow
//
//  Created by STUDENT on 10/5/25.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    @Published private(set) var favoriteCars: [Car] = []
    private let db = Firestore.firestore()
    
    private init() {
        loadFavorites()
    }
    
    // Get the current user's unique key for storing favorites
    private var currentUserKey: String {
        let currentUserEmail = UserProfileManager.shared.currentUserEmail
        if currentUserEmail.isEmpty {
            // Fallback to a default key if no user is logged in
            return "FavoriteCars_default"
        }
        return "FavoriteCars_\(currentUserEmail)"
    }
    
    func addToFavorites(_ car: Car) {
        if !favoriteCars.contains(where: { $0.id == car.id }) {
            favoriteCars.append(car)
            saveFavorites()
            saveToFirestore() // Sync to Firestore
        }
    }
    
    func removeFromFavorites(_ car: Car) {
        favoriteCars.removeAll { $0.id == car.id }
        saveFavorites()
        saveToFirestore() // Sync to Firestore
    }
    
    func isFavorite(_ car: Car) -> Bool {
        favoriteCars.contains { $0.id == car.id }
    }
    
    // Function to reload favorites when user changes (e.g., login/logout)
    func reloadFavoritesForCurrentUser() {
        loadFavorites()
    }
    
    // Function to clear favorites for current user (useful for account deletion)
    func clearFavorites() {
        favoriteCars = []
        UserDefaults.standard.removeObject(forKey: currentUserKey)
    }
    
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteCars) {
            UserDefaults.standard.set(encoded, forKey: currentUserKey)
        }
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: currentUserKey),
           let decoded = try? JSONDecoder().decode([Car].self, from: data) {
            favoriteCars = decoded
        } else {
            // Initialize with empty array for new users
            favoriteCars = []
        }
    }
    
    // MARK: - Firestore Sync Methods
    
    /// Save favorites to Firestore for current user
    private func saveToFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user, skipping Firestore sync")
            return
        }
        
        let favoritesData = favoriteCars.map { car in
            return [
                "id": car.id.uuidString,
                "name": car.name,
                "pricePerDay": car.pricePerDay,
                "imageName": car.imageName,
                "category": car.category,
                "rating": car.rating
            ] as [String : Any]
        }
        
        db.collection("users").document(userId).collection("favorites").document("favoritesList").setData([
            "cars": favoritesData,
            "lastUpdated": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error saving favorites to Firestore: \(error.localizedDescription)")
            } else {
                print("Favorites successfully saved to Firestore")
            }
        }
    }
    
    /// Load favorites from Firestore for current user
    func loadFromFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user, loading from UserDefaults only")
            loadFavorites()
            return
        }
        
        db.collection("users").document(userId).collection("favorites").document("favoritesList").getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Error loading favorites from Firestore: \(error.localizedDescription)")
                self?.loadFavorites() // Fallback to UserDefaults
                return
            }
            
            guard let data = snapshot?.data(),
                  let carsData = data["cars"] as? [[String: Any]] else {
                print("No favorites found in Firestore, loading from UserDefaults")
                self?.loadFavorites()
                return
            }
            
            let cars = carsData.compactMap { carDict -> Car? in
                guard let name = carDict["name"] as? String,
                      let pricePerDay = carDict["pricePerDay"] as? String,
                      let imageName = carDict["imageName"] as? String,
                      let rating = carDict["rating"] as? Int,
                      let category = carDict["category"] as? String else {
                    return nil
                }
                return Car(name: name, pricePerDay: pricePerDay, imageName: imageName, rating: rating, category: category)
            }
            
            DispatchQueue.main.async {
                self?.favoriteCars = cars
                self?.saveFavorites() // Save to UserDefaults as backup
                print("Favorites loaded from Firestore: \(cars.count) items")
            }
        }
    }
}
