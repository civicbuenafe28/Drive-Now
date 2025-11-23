//
//  CarSpecification.swift
//  DriveNow
//
//  Created by STUDENT on 10/15/25.
//

import Foundation

// MARK: - Car Specification Model
class CarSpecification: ObservableObject {
    let car: Car
    
    init(car: Car) {
        self.car = car
    }
    
    // MARK: - Computed Properties
    
    var availableModels: [String] {
        return ["2024", "2023", "2022", "2021"]
    }
    
    var fuelTypes: [String] {
        if car.belongsToCategory("Sports") {
            return ["Gasoline"]
        } else if car.belongsToCategory("Pickup") {
            return ["Petrol", "Diesel"]
        } else if car.belongsToCategory("SUV") && car.name == "Toyota Hycross" {
            return ["Hybrid"]
        } else {
            return ["Petrol", "Diesel", "Hybrid"]
        }
    }
    
    var transmissionTypes: [String] {
        return ["Manual", "Automatic"]
    }
    
    var seatCapacity: String {
        switch car.category {
        case "SUV":
            return car.name == "Hyundai Creta" ? "5 Seats" : "7 Seats"
        case "Sedan":
            return "4 Seats"
        case "Pickup":
            return car.name == "Ford F-150" ? "2 Seats" : "5 Seats"
        case "Luxury":
            return "4 Seats"
        case "Sports":
            return "2 Seats"
        case "Van":
            return "12 Seats"
        default:
            return "Unknown"
        }
    }
    
    var modelYear: String {
        let carHashValue = abs(car.name.hashValue)
        return availableModels[carHashValue % availableModels.count]
    }
    
    var fuelType: String {
        return fuelTypes.first ?? "Petrol"
    }
    
    var transmission: String {
        let carHashValue = abs(car.name.hashValue)
        return transmissionTypes[carHashValue % transmissionTypes.count]
    }
    
    // MARK: - Methods
    
    func getSpecifications() -> [String: String] {
        return [
            "Model": modelYear,
            "Seat Capacity": seatCapacity,
            "Fuel": fuelType,
            "Transmission": transmission
        ]
    }
    
    func getSpecificationValue(for key: String) -> String {
        return getSpecifications()[key] ?? "N/A"
    }
    
    // Method to check if car has specific specification
    func hasSpecification(_ specification: String) -> Bool {
        return getSpecifications().keys.contains(specification)
    }
    
    // Method to get detailed fuel efficiency info
    func getFuelEfficiency() -> String {
        switch fuelType {
        case "Hybrid":
            return "Excellent (35+ km/L)"
        case "Gasoline":
            return "Good (12-15 km/L)"
        case "Petrol":
            return "Good (10-14 km/L)"
        case "Diesel":
            return "Very Good (15-20 km/L)"
        default:
            return "Standard"
        }
    }
    
    // Method to get environmental impact rating
    func getEnvironmentalRating() -> String {
        switch fuelType {
        case "Hybrid":
            return "Eco-Friendly ⭐⭐⭐⭐⭐"
        case "Gasoline", "Petrol":
            return "Moderate ⭐⭐⭐"
        case "Diesel":
            return "Standard ⭐⭐"
        default:
            return "Not Rated"
        }
    }
}