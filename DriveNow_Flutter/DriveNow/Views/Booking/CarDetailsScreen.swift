//
//  CarDetailsScreen.swift
//  DriveNow
//
//  Created by STUDENT on 9/4/25.
//

import SwiftUI

struct CarDetailsScreen: View {
    let car: Car   // Updated to use Car model from Models folder
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var carSpecification: CarSpecification
    
    @Environment(\.presentationMode) var presentationMode

    // Initialize the CarSpecification with the car
    init(car: Car) {
        self.car = car
        self._carSpecification = StateObject(wrappedValue: CarSpecification(car: car))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.03, green: 0.11, blue: 0.26)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 15) {
                    
                    // MARK: - Top Bar
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Text("Car Details")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Spacer().frame(width: 24)
                    }
                    .padding(.top, 50)
                    .padding(.horizontal)
                    
                    // MARK: - Car Image
                    if !car.imageName.isEmpty {
                        Image(car.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding(.top, 10)
                    }
                    
                    // MARK: - Car Title + Rating
                    VStack(spacing: 5) {
                        Text(car.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        HStack {
                            Text(car.category)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            if car.isPremium() {
                                Text("• Premium")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        // Center-align the stars and rating text using OOP method
                        HStack {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(car.clampedRating) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text(String(format: "%.1f", car.clampedRating))
                            .foregroundColor(.white)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    // MARK: - Specifications using OOP model
                    VStack(alignment: .center, spacing: 15) {
                        Text("Car Specification:")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        ForEach(carSpecification.getSpecifications().keys.sorted(), id: \.self) { key in
                            specRow(label: key, value: carSpecification.getSpecificationValue(for: key))
                        }
                    }
                    .padding()
                    .background(Color(red: 0.15, green: 0.25, blue: 0.4))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // MARK: - Price with tier information
                    VStack {
                        Text("Rental Price:")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text("\(car.pricePerDay) / Day")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text(car.getPriceTier())
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.top, 5)
                    
                    // MARK: - Buttons Section (Stick together)
                    VStack(spacing: 8) {
                        // Add to Favorites Button
                        Button(action: {
                            if favoritesManager.isFavorite(car) {
                                favoritesManager.removeFromFavorites(car)
                            } else {
                                favoritesManager.addToFavorites(car)
                            }
                        }) {
                            HStack {
                                Image(systemName: favoritesManager.isFavorite(car) ? "heart.fill" : "heart")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(favoritesManager.isFavorite(car) ? .red : .white)
                                
                                Text(favoritesManager.isFavorite(car) ? "Remove from Favorites" : "Add to Favorites")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(favoritesManager.isFavorite(car) ? Color.red.opacity(0.8) : Color.gray.opacity(0.6))
                            .cornerRadius(12)
                        }
                        
                        // Book Now Button
                        NavigationLink(destination: BookingScreen(car: car)) {
                            Text("Book Now")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
    
    // MARK: - Helper Row
    func specRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.white.opacity(0.8))
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    CarDetailsScreen(
        car: Car(
            name: "Chevrolet Camaro",
            pricePerDay: "₱6,800",
            imageName: "chevrolet-camaro",
            rating: 5,
            category: "Sports"
        )
    )
}
