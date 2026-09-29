//
//  Car.swift
//  DriveNow
//
//  Created by STUDENT on 10/15/25.
//

import Foundation

class Car: ObservableObject, Identifiable, Codable {
    let id = UUID()
    let name: String
    let pricePerDay: String
    let imageName: String
    let rating: Int
    let category: String
    
    // Computed property to get price as Double for calculations
    var priceAsDouble: Double {
        let cleanedPrice = pricePerDay.replacingOccurrences(of: "₱", with: "").replacingOccurrences(of: ",", with: "")
        return Double(cleanedPrice) ?? 0.0
    }
    
    // Computed property to get formatted price
    var formattedPrice: String {
        return pricePerDay
    }
    
    // Computed property to get clamped rating (max 5.0)
    var clampedRating: Double {
        return min(Double(rating), 5.0)
    }
    
    // Computed property to get specifications
    var specifications: CarSpecification {
        return CarSpecification(car: self)
    }
    
    init(name: String, pricePerDay: String, imageName: String, rating: Int, category: String) {
        self.name = name
        self.pricePerDay = pricePerDay
        self.imageName = imageName
        self.rating = rating
        self.category = category
    }
    
    // Method to get star rating as string
    func getStarRating() -> String {
        return String(repeating: "⭐", count: rating)
    }
    
    // Method to check if car belongs to specific category
    func belongsToCategory(_ category: String) -> Bool {
        return self.category.lowercased() == category.lowercased()
    }
    
    // Method to get car details as formatted string
    func getCarDetails() -> String {
        return "\(name) - \(pricePerDay)/day - Rating: \(getStarRating())"
    }
    
    // Method to get detailed car information
    func getDetailedInfo() -> [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "category": category,
            "price": priceAsDouble,
            "rating": clampedRating,
            "specifications": specifications.getSpecifications()
        ]
    }
    
    // Method to check if car is premium (rating >= 4)
    func isPremium() -> Bool {
        return clampedRating >= 4.0
    }
    
    // Method to get price tier
    func getPriceTier() -> String {
        let price = priceAsDouble
        switch price {
        case 0..<3000:
            return "Budget"
        case 3000..<6000:
            return "Standard"
        case 6000..<10000:
            return "Premium"
        default:
            return "Luxury"
        }
    }
    
    // Method to check if car is available for long-term rental
    func isAvailableForLongTerm() -> Bool {
        // Long-term rentals typically for cars with good ratings
        return clampedRating >= 3.5
    }
}

// MARK: - Equatable conformance for comparison
extension Car: Equatable {
    static func == (lhs: Car, rhs: Car) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Hashable conformance for use in Sets
extension Car: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
