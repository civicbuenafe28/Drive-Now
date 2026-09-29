//
//  HomeTab.swift
//  DriveNow
//
//  Created by STUDENT on 8/27/25.
//

import SwiftUI

struct HomeTab: View {
    @State private var searchText = ""
    @State private var selectedCategory: String = "SUV"

    // Remove the nested Car struct - now using Car model from Models folder
    
    let cars: [Car] = [
        Car(name: "Toyota Innova HyCross", pricePerDay: "₱2,500", imageName: "toyota-innova", rating: 4, category: "SUV"),
        Car(name: "Toyota Fortuner", pricePerDay: "₱3,000", imageName: "toyota-fortuner", rating: 4, category: "SUV"),
        Car(name: "Hyundai Creta", pricePerDay: "₱2,800", imageName: "hyundai-creta", rating: 4, category: "SUV"),
        Car(name: "Ford Everest", pricePerDay: "₱3,500", imageName: "ford-everest", rating: 5, category: "SUV"),
        Car(name: "Mitsubishi Montero", pricePerDay: "₱3,200", imageName: "mitsubishi-montero", rating: 4, category: "SUV"),
         
        Car(name: "Honda Civic", pricePerDay: "₱2,000", imageName: "honda-civic", rating: 5, category: "Sedan"),
        Car(name: "Toyota Camry", pricePerDay: "₱2,400", imageName: "toyota-camry", rating: 4, category: "Sedan"),
        Car(name: "Nissan Sentra", pricePerDay: "₱1,900", imageName: "nissan-sentra", rating: 3, category: "Sedan"),
        Car(name: "Mazda 3", pricePerDay: "₱2,100", imageName: "mazda-3", rating: 4, category: "Sedan"),
        Car(name: "Subaru Impreza", pricePerDay: "₱2,300", imageName: "subaru-impreza", rating: 5, category: "Sedan"),
         
        Car(name: "Ford F-150", pricePerDay: "₱4,000", imageName: "ford-f150", rating: 3, category: "Pickup"),
        Car(name: "Toyota Hilux", pricePerDay: "₱3,800", imageName: "toyota-hilux", rating: 4, category: "Pickup"),
        Car(name: "Nissan Navara", pricePerDay: "₱3,700", imageName: "nissan-navara", rating: 4, category: "Pickup"),
        Car(name: "Isuzu D-Max", pricePerDay: "₱3,600", imageName: "isuzu-dmax", rating: 5, category: "Pickup"),
        Car(name: "Mitsubishi Strada", pricePerDay: "₱3,500", imageName: "mitsubishi-strada", rating: 4, category: "Pickup"),
         
        Car(name: "Mercedes-Benz S-Class", pricePerDay: "₱10,000", imageName: "mercedes-s-class", rating: 5, category: "Luxury"),
        Car(name: "BMW 7 Series", pricePerDay: "₱9,500", imageName: "bmw-7-series", rating: 5, category: "Luxury"),
        Car(name: "Audi A8", pricePerDay: "₱9,000", imageName: "audi-a8", rating: 4, category: "Luxury"),
        Car(name: "Lexus LS", pricePerDay: "₱8,800", imageName: "lexus-ls", rating: 5, category: "Luxury"),
        Car(name: "Jaguar XJ", pricePerDay: "₱8,500", imageName: "jaguar-xj", rating: 4, category: "Luxury"),

        Car(name: "Ford Mustang GT", pricePerDay: "₱7,000", imageName: "ford-mustang", rating: 5, category: "Sports"),
        Car(name: "Chevrolet Camaro", pricePerDay: "₱6,800", imageName: "chevrolet-camaro", rating: 4, category: "Sports"),
        Car(name: "Nissan GT-R", pricePerDay: "₱12,000", imageName: "nissan-gtr", rating: 5, category: "Sports"),
        Car(name: "Porsche 911", pricePerDay: "₱15,000", imageName: "porsche-911", rating: 5, category: "Sports"),
        Car(name: "Toyota Supra", pricePerDay: "₱7,500", imageName: "toyota-supra", rating: 4, category: "Sports"),

        Car(name: "Toyota Hiace", pricePerDay: "₱3,500", imageName: "toyota-hiace", rating: 4, category: "Van"),
        Car(name: "Ford Transit", pricePerDay: "₱3,200", imageName: "ford-transit", rating: 3, category: "Van"),
        Car(name: "Nissan Urvan", pricePerDay: "₱3,000", imageName: "nissan-urvan", rating: 4, category: "Van"),
        Car(name: "Hyundai Starex", pricePerDay: "₱2,900", imageName: "hyundai-starex", rating: 3, category: "Van"),
        Car(name: "Foton Traveller XL", pricePerDay: "₱3,300", imageName: "foton-xl", rating: 5, category: "Van")
    ]
     
    var filteredCars: [Car] {
        let carsByCategory = cars.filter { car in
            car.belongsToCategory(selectedCategory)
        }
         
        if searchText.isEmpty {
            return carsByCategory
        } else {
            return carsByCategory.filter { car in 
                car.name.lowercased().contains(searchText.lowercased()) 
            }
        }
    }

    let categories = ["SUV", "Sedan", "Pickup", "Luxury", "Sports", "Van"]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(red: 0.03, green: 0.11, blue: 0.26)
                    .edgesIgnoringSafeArea(.all)

                ZStack(alignment: .top) {
                    Image("logo") // Logo at the top-center
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .offset(y: -35)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

                VStack(spacing: 0) {
                    HStack {
                        Text("Home")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        NavigationLink(destination: FavoritesScreen()) {
                            Image(systemName: "heart")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 50)

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search cars by name or brand", text: $searchText)
                            .foregroundColor(.black)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 5)
                    .padding(.bottom, 5)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    Text(category)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 15)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == category ? Color.blue : Color(red: 0.25, green: 0.45, blue: 0.8))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 10)

                    ScrollView(.vertical, showsIndicators: false) {
                        if filteredCars.isEmpty {
                            Text("No Match Found")
                                .foregroundColor(.white)
                                .font(.title3)
                                .padding(.top, 50)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            VStack(spacing: 15) {
                                ForEach(filteredCars) { car in
                                    VStack(alignment: .leading, spacing: 0) {
                                        CarImageView(car: car)
                                            .padding(.horizontal, 10)
                                        
                                        CarDetailsView(car: car)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                    }
                                    .background(Color(red: 0.03, green: 0.11, blue: 0.26))
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.top, 5)
                            .padding(.bottom, 80)
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    HStack(alignment: .center) {
                        // Corrected: Home tab is selected
                        TabItemView(imageName: "house.fill", title: "Home", isSelected: true)

                        // Corrected: NavigationLink for My Rentals
                        NavigationLink(destination: MyRentalsScreen()) {
                            TabItemView(imageName: "list.bullet.rectangle.portrait.fill", title: "My Rentals", isSelected: false)
                        }

                        // **Updated:** NavigationLink for Profile — use environment-based ProfileScreen
                        NavigationLink(destination: ProfileScreen()) {
                            TabItemView(imageName: "person.fill", title: "Profile", isSelected: false)
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
            .navigationBarBackButtonHidden(true) // Hide the back button in HomeTab
        }
    }
}

// MARK: - Tab Bar Item View
struct TabItemView: View {
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

struct CarImageView: View {
    let car: Car

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !car.imageName.isEmpty {
                Image(car.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
    }
}

struct CarDetailsView: View {
    let car: Car

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(car.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
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
                Text(car.formattedPrice + "/Day")
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
    HomeTab()
}
