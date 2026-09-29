//
//  RentalLocation.swift
//  DriveNow
//
//  Created by STUDENT on 10/15/25.
//

import Foundation

// MARK: - Rental Location Model
class RentalLocation: ObservableObject, Identifiable, Codable {
    let id = UUID()
    let name: String
    let address: String
    let city: String
    let zipCode: String
    let phoneNumber: String
    let latitude: Double
    let longitude: Double
    @Published var operatingHours: OperatingHours
    @Published var availableServices: [LocationService]
    @Published var isActive: Bool
    
    // MARK: - Computed Properties
    
    var fullAddress: String {
        return "\(address), \(city) \(zipCode)"
    }
    
    var isCurrentlyOpen: Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTime = currentHour * 60 + currentMinute
        
        return currentTime >= operatingHours.openingTimeInMinutes &&
               currentTime <= operatingHours.closingTimeInMinutes &&
               isActive
    }
    
    var servicesDescription: String {
        return availableServices.map { $0.displayName }.joined(separator: ", ")
    }
    
    // MARK: - Initialization
    
    init(name: String, address: String, city: String, zipCode: String, phoneNumber: String, latitude: Double, longitude: Double, operatingHours: OperatingHours) {
        self.name = name
        self.address = address
        self.city = city
        self.zipCode = zipCode
        self.phoneNumber = phoneNumber
        self.latitude = latitude
        self.longitude = longitude
        self.operatingHours = operatingHours
        self.availableServices = [.carRental, .customerService]
        self.isActive = true
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, name, address, city, zipCode, phoneNumber, latitude, longitude, operatingHours, availableServices, isActive
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let address = try container.decode(String.self, forKey: .address)
        let city = try container.decode(String.self, forKey: .city)
        let zipCode = try container.decode(String.self, forKey: .zipCode)
        let phoneNumber = try container.decode(String.self, forKey: .phoneNumber)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        let operatingHours = try container.decode(OperatingHours.self, forKey: .operatingHours)
        
        self.init(name: name, address: address, city: city, zipCode: zipCode, phoneNumber: phoneNumber, latitude: latitude, longitude: longitude, operatingHours: operatingHours)
        
        self.availableServices = try container.decode([LocationService].self, forKey: .availableServices)
        self.isActive = try container.decode(Bool.self, forKey: .isActive)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
        try container.encode(city, forKey: .city)
        try container.encode(zipCode, forKey: .zipCode)
        try container.encode(phoneNumber, forKey: .phoneNumber)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(operatingHours, forKey: .operatingHours)
        try container.encode(availableServices, forKey: .availableServices)
        try container.encode(isActive, forKey: .isActive)
    }
    
    // MARK: - Methods
    
    func hasService(_ service: LocationService) -> Bool {
        return availableServices.contains(service)
    }
    
    func addService(_ service: LocationService) {
        if !availableServices.contains(service) {
            availableServices.append(service)
        }
    }
    
    func removeService(_ service: LocationService) {
        availableServices.removeAll { $0 == service }
    }
    
    func getDistanceFrom(latitude: Double, longitude: Double) -> Double {
        let earthRadius = 6371.0 // Earth's radius in kilometers
        
        let lat1Rad = self.latitude * .pi / 180
        let lat2Rad = latitude * .pi / 180
        let deltaLat = (latitude - self.latitude) * .pi / 180
        let deltaLon = (longitude - self.longitude) * .pi / 180
        
        let a = sin(deltaLat/2) * sin(deltaLat/2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLon/2) * sin(deltaLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return earthRadius * c
    }
    
    func getOperatingStatus() -> String {
        if !isActive {
            return "Temporarily Closed"
        }
        return isCurrentlyOpen ? "Open Now" : "Closed"
    }
    
    func getNextOpeningTime() -> String {
        if isCurrentlyOpen {
            return "Open until \(operatingHours.closingTimeFormatted)"
        } else {
            return "Opens at \(operatingHours.openingTimeFormatted)"
        }
    }
    
    func canProvideService(_ service: LocationService) -> Bool {
        return isActive && hasService(service)
    }
}

// MARK: - Operating Hours Structure
struct OperatingHours: Codable {
    let openingTimeInMinutes: Int // Minutes from midnight
    let closingTimeInMinutes: Int // Minutes from midnight
    
    var openingTimeFormatted: String {
        let hours = openingTimeInMinutes / 60
        let minutes = openingTimeInMinutes % 60
        return String(format: "%02d:%02d", hours, minutes)
    }
    
    var closingTimeFormatted: String {
        let hours = closingTimeInMinutes / 60
        let minutes = closingTimeInMinutes % 60
        return String(format: "%02d:%02d", hours, minutes)
    }
    
    init(openingHour: Int, openingMinute: Int = 0, closingHour: Int, closingMinute: Int = 0) {
        self.openingTimeInMinutes = openingHour * 60 + openingMinute
        self.closingTimeInMinutes = closingHour * 60 + closingMinute
    }
}

// MARK: - Location Service Enum
enum LocationService: String, CaseIterable, Codable {
    case carRental = "car_rental"
    case carWash = "car_wash"
    case maintenance = "maintenance"
    case customerService = "customer_service"
    case vipLounge = "vip_lounge"
    case fastCheckIn = "fast_check_in"
    case delivery = "delivery"
    case pickup = "pickup"
    
    var displayName: String {
        switch self {
        case .carRental:
            return "Car Rental"
        case .carWash:
            return "Car Wash"
        case .maintenance:
            return "Maintenance"
        case .customerService:
            return "Customer Service"
        case .vipLounge:
            return "VIP Lounge"
        case .fastCheckIn:
            return "Fast Check-in"
        case .delivery:
            return "Delivery Service"
        case .pickup:
            return "Pickup Service"
        }
    }
    
    var iconName: String {
        switch self {
        case .carRental:
            return "car.fill"
        case .carWash:
            return "drop.fill"
        case .maintenance:
            return "wrench.fill"
        case .customerService:
            return "person.fill.checkmark"
        case .vipLounge:
            return "crown.fill"
        case .fastCheckIn:
            return "checkmark.circle.fill"
        case .delivery:
            return "shippingbox.fill"
        case .pickup:
            return "location.fill"
        }
    }
}

// MARK: - Extensions
extension RentalLocation: Equatable {
    static func == (lhs: RentalLocation, rhs: RentalLocation) -> Bool {
        return lhs.id == rhs.id
    }
}

extension RentalLocation: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
