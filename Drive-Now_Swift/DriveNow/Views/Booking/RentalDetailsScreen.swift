//
//  RentalDetailsScreen.swift
//  DriveNow
//
//  Created by STUDENT on 10/7/25.
//

import SwiftUI

struct RentalDetailsScreen: View {
    let booking: CarBooking
    @Environment(\.dismiss) var dismiss
    @StateObject private var rentalManager = RentalManager.shared
    @State private var showCancelConfirmation = false
    @State private var showCancelSuccess = false
    
    // Calculate rental days
    var rentalDays: Int {
        let calendar = Calendar.current
        let startOfPickUpDay = calendar.startOfDay(for: booking.pickUpDate)
        let startOfReturnDay = calendar.startOfDay(for: booking.returnDate)
        let numberOfDays = calendar.dateComponents([.day], from: startOfPickUpDay, to: startOfReturnDay).day ?? 0
        return max(numberOfDays, 1) // Minimum 1 day
    }
    
    // Calculate total cost
    var totalCost: String {
        // Extract price from the car's price per day string
        let priceString = booking.pricePerDay.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let pricePerDay = Int(priceString) ?? 0
        let total = rentalDays * pricePerDay
        return formattedAmount(total)
    }
    
    // Format number with comma separators
    func formattedAmount(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.locale = Locale(identifier: "en_PH")
        return "₱" + (formatter.string(from: NSNumber(value: amount)) ?? "0")
    }
    
    // Generate random car owner name
    var randomOwnerName: String {
        let firstNames = ["Maria", "Juan", "Jose", "Ana", "Carlos", "Elena", "Miguel", "Sofia", "Roberto", "Carmen", "Luis", "Isabella", "Diego", "Gabriela", "Antonio"]
        let lastNames = ["Santos", "Reyes", "Cruz", "Bautista", "Garcia", "Gonzales", "Ramos", "Flores", "Mendoza", "Torres", "Rivera", "Morales", "Aquino", "Dela Cruz", "Villanueva"]
        
        // Use booking's hash to ensure consistent results for the same booking
        let seed = abs(booking.id.hashValue)
        let firstIndex = seed % firstNames.count
        let lastIndex = (seed / firstNames.count) % lastNames.count
        
        return "\(firstNames[firstIndex]) \(lastNames[lastIndex])"
    }
    
    // Generate random Philippine contact number
    var randomContactNumber: String {
        let prefixes = ["0917", "0918", "0919", "0920", "0921", "0922", "0923", "0924", "0925", "0926", "0927", "0928", "0929", "0939", "0949", "0998", "0999"]
        
        // Use booking's hash to ensure consistent results for the same booking
        let seed = abs(booking.id.hashValue)
        let prefixIndex = seed % prefixes.count
        let suffix = String(format: "%07d", (seed % 9000000) + 1000000)
        
        // Format: 0919 235 7342 (4 digits, space, 3 digits, space, 4 digits)
        let firstPart = String(suffix.prefix(3))  // First 3 digits after prefix
        let secondPart = String(suffix.suffix(4)) // Last 4 digits
        
        return "\(prefixes[prefixIndex]) \(firstPart) \(secondPart)"
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.11, blue: 0.26)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Fixed Header (Non-scrollable)
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                    }
                    Spacer()
                    Text("Rental Details")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                .background(Color(red: 0.03, green: 0.11, blue: 0.26))
                
                // Scrollable Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Car Image and Name
                        VStack(spacing: 15) {
                            Image(booking.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 140)
                                .cornerRadius(15)
                                .shadow(radius: 5)
                            
                            Text(booking.carName)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            // Status Badge
                            HStack {
                                if booking.status == "Active" {
                                    Text("Active")
                                        .font(.system(size: 16, weight: .bold))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(20)
                                } else if booking.status == "Completed" {
                                    Text("Completed")
                                        .font(.system(size: 16, weight: .bold))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(Color.gray.opacity(0.6))
                                        .foregroundColor(.white)
                                        .cornerRadius(20)
                                } else if booking.status == "Upcoming" {
                                    Text("Upcoming")
                                        .font(.system(size: 16, weight: .bold))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        // Booking Details Card
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Booking Information")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 15) {
                                // Pick-up Date
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 18))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Pick-up Date")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                        Text(booking.pickUpDate.formatted(date: .abbreviated, time: .shortened))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.3))
                                
                                // Return Date
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 18))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Return Date")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                        Text(booking.returnDate.formatted(date: .abbreviated, time: .shortened))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.3))
                                
                                // Location
                                HStack {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.red)
                                        .font(.system(size: 18))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Pickup Location")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                        Text(booking.location)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(red: 0.13, green: 0.23, blue: 0.45))
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                        
                        // Car Owner Information Card
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Car Owner Information")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 15) {
                                // Owner Name
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 18))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Owner Name")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                        Text(randomOwnerName)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.3))
                                
                                // Contact Number
                                HStack {
                                    Image(systemName: "phone.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 18))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Contact Number")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                        Text(randomContactNumber)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(red: 0.13, green: 0.23, blue: 0.45))
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                        
                        // Cost Breakdown Card
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Cost Breakdown")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Price per day:")
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Text(booking.pricePerDay)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                HStack {
                                    Text("Rental duration:")
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Text("\(rentalDays) days")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.3))
                                
                                HStack {
                                    Text("Total Cost:")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(totalCost)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(red: 0.13, green: 0.23, blue: 0.45))
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                        
                        // Cancel Booking Button (only show for Active and Upcoming bookings)
                        if booking.status == "Active" || booking.status == "Upcoming" {
                            Button(action: {
                                showCancelConfirmation = true
                            }) {
                                Text("Cancel Booking")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(15)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Cancel Booking", isPresented: $showCancelConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .destructive) {
                // Cancel the booking
                rentalManager.cancelBooking(booking)
                showCancelSuccess = true
            }
        } message: {
            Text("Are you sure you want to cancel this booking? This action cannot be undone.")
        }
        .alert("✅ Booking Successfully Canceled", isPresented: $showCancelSuccess) {
            Button("OK") {
                dismiss() // Go back to MyRentalsScreen
            }
        } message: {
            Text("Your booking has been canceled successfully.")
        }
    }
}

struct RentalDetailsScreen_Previews: PreviewProvider {
    static var previews: some View {
        RentalDetailsScreen(
            booking: CarBooking(
                carName: "Honda Civic",
                imageName: "honda-civic",
                pricePerDay: "₱2,500",
                pickUpDate: Date(),
                returnDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                location: "Manila, Philippines",
                createdAt: Date()
            )
        )
    }
}
