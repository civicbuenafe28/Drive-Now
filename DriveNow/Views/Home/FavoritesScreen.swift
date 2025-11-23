//
//  FavoritesScreen.swift
//  DriveNow
//
//  Created by STUDENT on 10/5/25.
//

import SwiftUI

struct FavoritesScreen: View {
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.03, green: 0.11, blue: 0.26)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
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
                        Text("Favorites")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Spacer().frame(width: 24)
                    }
                    .padding(.top, 50)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    
                    // MARK: - Favorites List
                    if favoritesManager.favoriteCars.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "heart.slash")
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("No Favorites Yet")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Add cars to your favorites by tapping the heart icon in car details")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(favoritesManager.favoriteCars) { car in
                                    VStack(alignment: .leading, spacing: 0) {
                                        FavoriteCarImageView(car: car)
                                            .padding(.horizontal, 10)
                                        
                                        FavoriteCarDetailsView(car: car)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                    }
                                    .background(Color(red: 0.03, green: 0.11, blue: 0.26))
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal, 15)
                            .padding(.bottom, 50)
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                // Reload favorites when screen appears to ensure fresh data
                favoritesManager.reloadFavoritesForCurrentUser()
            }
        }
    }
}

// MARK: - Favorite Car Image View
struct FavoriteCarImageView: View {
    let car: Car

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !car.imageName.isEmpty {
                Image(car.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width - 60, height: 160)
                    .clipped()
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
    }
}

// MARK: - Favorite Car Details View
struct FavoriteCarDetailsView: View {
    let car: Car
    @StateObject private var favoritesManager = FavoritesManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(car.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                
                // Remove from favorites button
                Button(action: {
                    favoritesManager.removeFromFavorites(car)
                }) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.red)
                }
                .padding(.trailing, 10)
                
                NavigationLink(destination: CarDetailsScreen(car: car)) {
                    Text("View")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            
            HStack {
                Text("\(car.pricePerDay)/Day")
                    .font(.subheadline)
                    .foregroundColor(.white)
                 
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < car.rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
            }
        }
    }
}

#Preview {
    FavoritesScreen()
}
