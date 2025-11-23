//
//  MyRentalsScreen.swift
//  DriveNow
//
//  Created by STUDENT on 9/9/25.
//

import SwiftUI

struct MyRentalsScreen: View {
    @ObservedObject private var rentalManager = RentalManager.shared

    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.11, blue: 0.26)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                Text("My Rentals")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 50)
                    .padding(.bottom, 20)

                if rentalManager.bookings.isEmpty {
                    // Enhanced empty state design
                    VStack(spacing: 40) {
                        Spacer()
                        
                        // Car icon illustration with enhanced design
                        VStack(spacing: 25) {
                            ZStack {
                                // Outer glow effect
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 140, height: 140)
                                
                                // Main background circle
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 120, height: 120)
                                
                                // Car icon with animation
                                Image(systemName: "car.fill")
                                    .font(.system(size: 55, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .scaleEffect(1.0)
                                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: UUID())
                            }
                            
                            // Enhanced messaging
                            VStack(spacing: 15) {
                                Text("No Rental Bookings Yet")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text("Ready to hit the road?")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.blue.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                
                                Text("Explore our premium fleet and find your perfect vehicle")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 35)
                                    .lineLimit(4)
                            }
                        }
                        
                        // Enhanced action buttons
                        VStack(spacing: 15) {
                            // Primary action button
                            NavigationLink(destination: HomeTab()) {
                                HStack(spacing: 15) {
                                    Image(systemName: "car.circle.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                    Text("Browse Cars")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 35)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(30)
                                .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Display list of car bookings as cards in descending order (latest first)
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(rentalManager.bookings.sorted { $0.createdAt > $1.createdAt }) { booking in
                                NavigationLink(destination: RentalDetailsScreen(booking: booking)) {
                                    CarBookingCardView(booking: booking)
                                }
                                .buttonStyle(PlainButtonStyle()) // Prevents the default button styling
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.bottom, 100) // Add bottom padding to ensure last item is visible above tab bar
                    }
                }

                Spacer(minLength: 0)

                // Bottom Tab Bar with NavigationLink for Home
                HStack(alignment: .center) {
                    NavigationLink(destination: HomeTab()) {
                        MyRentalsTabItemView(imageName: "house.fill", title: "Home", isSelected: false)
                    }
                    NavigationLink(destination: MyRentalsScreen()) {
                        MyRentalsTabItemView(imageName: "list.bullet.rectangle.portrait.fill", title: "My Rentals", isSelected: true)
                    }
                    NavigationLink(destination: ProfileScreen()) {
                        MyRentalsTabItemView(imageName: "person.fill", title: "Profile", isSelected: false)
                    }
                }
                .padding(.vertical, 10)
                .background(Color(red: 0.03, green: 0.11, blue: 0.26))
                .cornerRadius(20)
                .shadow(radius: 5)
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            rentalManager.reloadBookingsForCurrentUser()
        }
    }
}

// MARK: - Car Booking Card View
struct CarBookingCardView: View {
    let booking: CarBooking

    var body: some View {
        VStack(spacing: 0) {
            // Main content row
            HStack(alignment: .center, spacing: 15) {
                Image(booking.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 70)
                    .cornerRadius(10)
                    .shadow(radius: 3)

                VStack(alignment: .leading, spacing: 6) {
                    Text(booking.carName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Text("Rent Date: \(booking.dateRangeString)")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                }
                
                Spacer()
                
                // Status badge in original position
                if booking.status == "Active" {
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                } else if booking.status == "Completed" {
                    Text("Completed")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(15)
                } else if booking.status == "Upcoming" {
                    Text("Upcoming")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.13, green: 0.23, blue: 0.45))
        .cornerRadius(16)
        .shadow(radius: 4)
        .padding(.horizontal, 20)
    }
}

// MARK: - Tab Bar Item View
struct MyRentalsTabItemView: View {
    let imageName: String
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack {
            Image(systemName: imageName)
                .font(.system(size: 24))
                .foregroundColor(isSelected ? .blue : .white)
            Text(title)
                .font(.caption)
                .foregroundColor(isSelected ? .blue : .white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
    }
}

#Preview {
    MyRentalsScreen()
        .preferredColorScheme(.dark)
}
