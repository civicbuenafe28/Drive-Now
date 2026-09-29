//
//  LocationPickerView.swift
//  DriveNow
//
//  Created by STUDENT on 10/2/25.
//

import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var selectedAddress: String
    @Binding var showMapPicker: Bool
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 14.5995, longitude: 120.9842), // Manila, Philippines
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    @State private var annotations: [LocationAnnotation] = []
    @StateObject private var locationManager = LocationManager()
    @State private var mapRect: CGRect = .zero
    @State private var showConfirmButton = false
    
    var body: some View {
        NavigationView {
            ZStack {
                GeometryReader { geometry in
                    Map(coordinateRegion: $region, annotationItems: annotations) { annotation in
                        MapPin(coordinate: annotation.coordinate, tint: .red)
                    }
                    .onTapGesture { location in
                        // Convert tap location to actual coordinate
                        let coordinate = convertTapToCoordinate(
                            tapPoint: location,
                            mapSize: geometry.size,
                            region: region
                        )
                        selectedCoordinate = coordinate
                        
                        // Update annotations to show pin at tapped location
                        annotations = [LocationAnnotation(coordinate: coordinate)]
                        
                        // Show confirm button when location is pinned
                        showConfirmButton = true
                        
                        // Get the address name for this specific coordinate
                        reverseGeocode(coordinate: coordinate)
                    }
                    .onAppear {
                        mapRect = CGRect(origin: .zero, size: geometry.size)
                    }
                }
                
                // Zoom Controls
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            // Zoom In Button
                            Button(action: {
                                zoomIn()
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            }
                            
                            // Zoom Out Button
                            Button(action: {
                                zoomOut()
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            }
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.top, 20)
                    Spacer()
                }
                
                // Confirm Location Button - appears at bottom when location is selected
                if showConfirmButton {
                    VStack {
                        Spacer()
                        Button(action: {
                            showMapPicker = false
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                Text("Confirm Location")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(25)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    showMapPicker = false
                },
                trailing: Button("Done") {
                    showMapPicker = false
                }
                .disabled(selectedCoordinate == nil)
            )
        }
    }
    
    // Zoom In function
    private func zoomIn() {
        withAnimation(.easeInOut(duration: 0.3)) {
            region.span.latitudeDelta = max(region.span.latitudeDelta * 0.5, 0.001)
            region.span.longitudeDelta = max(region.span.longitudeDelta * 0.5, 0.001)
        }
    }
    
    // Zoom Out function
    private func zoomOut() {
        withAnimation(.easeInOut(duration: 0.3)) {
            region.span.latitudeDelta = min(region.span.latitudeDelta * 2.0, 180.0)
            region.span.longitudeDelta = min(region.span.longitudeDelta * 2.0, 360.0)
        }
    }
    
    // Helper function to convert tap point to coordinate
    private func convertTapToCoordinate(
        tapPoint: CGPoint,
        mapSize: CGSize,
        region: MKCoordinateRegion
    ) -> CLLocationCoordinate2D {
        let latitudeDelta = region.span.latitudeDelta
        let longitudeDelta = region.span.longitudeDelta
        
        let relativeX = tapPoint.x / mapSize.width
        let relativeY = tapPoint.y / mapSize.height
        
        let latitude = region.center.latitude - (relativeY - 0.5) * latitudeDelta
        let longitude = region.center.longitude + (relativeX - 0.5) * longitudeDelta
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // Function to reverse geocode coordinate to address
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    var addressComponents: [String] = []
                    
                    if let name = placemark.name {
                        addressComponents.append(name)
                    }
                    if let locality = placemark.locality {
                        addressComponents.append(locality)
                    }
                    if let country = placemark.country {
                        addressComponents.append(country)
                    }
                    
                    selectedAddress = addressComponents.joined(separator: ", ")
                }
            }
        }
    }
}

// Location annotation for map pins
struct LocationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// Location manager for current location
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        currentLocation = location.coordinate
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
