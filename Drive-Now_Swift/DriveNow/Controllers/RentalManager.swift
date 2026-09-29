//
//  RentalManager.swift
//  DriveNow
//
//  Created by STUDENT on 10/2/25.
//

import Foundation
import SwiftUI

// MARK: - Shared Rental Manager
class RentalManager: ObservableObject {
    static let shared = RentalManager()
    
    @Published var bookings: [CarBooking] = []
    
    private init() {
        loadBookingsForCurrentUser()
    }
    
    private var currentUserKey: String {
        let currentUserEmail = UserProfileManager.shared.currentUserEmail
        if !currentUserEmail.isEmpty {
            return "RentalBookings_\(currentUserEmail)"
        }
        return "RentalBookings_default"
    }
    
    private func loadBookingsForCurrentUser() {
        if let data = UserDefaults.standard.data(forKey: currentUserKey),
           let decodedBookings = try? JSONDecoder().decode([CarBooking].self, from: data) {
            self.bookings = decodedBookings
        } else {
            self.bookings = []
        }
    }
    
    private func saveBookings() {
        if let encoded = try? JSONEncoder().encode(bookings) {
            UserDefaults.standard.set(encoded, forKey: currentUserKey)
        }
    }
    
    func addBooking(car: Car, pickUpDate: Date, returnDate: Date, location: String) {
        let booking = CarBooking(
            carName: car.name,
            imageName: car.imageName,
            pricePerDay: car.pricePerDay,
            pickUpDate: pickUpDate,
            returnDate: returnDate,
            location: location,
            createdAt: Date()
        )
        bookings.append(booking)
        saveBookings()
    }
    
    func cancelBooking(_ booking: CarBooking) {
        bookings.removeAll { $0.id == booking.id }
        saveBookings()
    }
    
    // Reload bookings for current user (useful when switching accounts)
    func reloadBookingsForCurrentUser() {
        loadBookingsForCurrentUser()
    }
    
    // Clear all bookings for current user
    func clearBookings() {
        bookings = []
        saveBookings()
    }
    
    // Admin function: Get bookings for a specific user
    func getBookingsForUser(email: String) -> [CarBooking] {
        let key = "RentalBookings_\(email)"
        if let data = UserDefaults.standard.data(forKey: key),
           let decodedBookings = try? JSONDecoder().decode([CarBooking].self, from: data) {
            return decodedBookings
        }
        return []
    }
    
    // Get upcoming bookings
    func getUpcomingBookings() -> [CarBooking] {
        return bookings.filter { $0.getBookingStatus() == "Upcoming" }
    }
    
    // Get active bookings
    func getActiveBookings() -> [CarBooking] {
        return bookings.filter { $0.getBookingStatus() == "Active" }
    }
    
    // Get completed bookings
    func getCompletedBookings() -> [CarBooking] {
        return bookings.filter { $0.getBookingStatus() == "Completed" }
    }
}
