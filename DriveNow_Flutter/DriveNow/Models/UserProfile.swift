//
//  CarBooking.swift
//  DriveNow
//
//  Created by STUDENT on 10/15/25.
//

import Foundation

class CarBooking: ObservableObject, Identifiable, Codable {
    let id = UUID()
    let carName: String
    let imageName: String
    let pricePerDay: String
    let pickUpDate: Date
    let returnDate: Date
    let location: String
    let createdAt: Date
    
    // Computed property to calculate total days
    var totalDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: pickUpDate, to: returnDate)
        return max(1, components.day ?? 1) // Minimum 1 day
    }
    
    // Computed property to calculate total cost
    var totalCost: Double {
        let pricePerDayValue = pricePerDay.replacingOccurrences(of: "₱", with: "").replacingOccurrences(of: ",", with: "")
        let dailyRate = Double(pricePerDayValue) ?? 0.0
        return dailyRate * Double(totalDays)
    }
    
    // Computed property to get formatted total cost
    var formattedTotalCost: String {
        return "₱\(String(format: "%.0f", totalCost))"
    }
    
    // Computed property to get booking status
    var status: String {
        return getBookingStatus()
    }
    
    // Computed property to get formatted date range string
    var dateRangeString: String {
        return getDateRange()
    }
    
    init(carName: String, imageName: String, pricePerDay: String, pickUpDate: Date, returnDate: Date, location: String, createdAt: Date = Date()) {
        self.carName = carName
        self.imageName = imageName
        self.pricePerDay = pricePerDay
        self.pickUpDate = pickUpDate
        self.returnDate = returnDate
        self.location = location
        self.createdAt = createdAt
    }
    
    // Method to get booking status
    func getBookingStatus() -> String {
        let now = Date()
        if now < pickUpDate {
            return "Upcoming"
        } else if now >= pickUpDate && now <= returnDate {
            return "Active"
        } else {
            return "Completed"
        }
    }
    
    // Method to get formatted date range
    func getDateRange() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return "\(formatter.string(from: pickUpDate)) - \(formatter.string(from: returnDate))"
    }
    
    // Method to check if booking can be cancelled
    func canBeCancelled() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let hoursUntilPickup = calendar.dateComponents([.hour], from: now, to: pickUpDate).hour ?? 0
        return hoursUntilPickup > 24 // Can cancel if more than 24 hours before pickup
    }
}

// MARK: - Equatable conformance for comparison
extension CarBooking: Equatable {
    static func == (lhs: CarBooking, rhs: CarBooking) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Hashable conformance for use in Sets
extension CarBooking: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
