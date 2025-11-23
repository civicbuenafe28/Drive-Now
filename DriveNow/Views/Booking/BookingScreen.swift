//
//  BookingScreen.swift
//  DriveNow
//
//  Created by STUDENT on 9/9/25.
//

import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore

struct BookingScreen: View {
    @State private var pickUpDate: Date = Date()
    @State private var returnDate: Date = Date()
    @State private var location = ""
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedAddress: String = ""
    @State private var showMapPicker = false
    @State private var isShowingPickUpDatePicker = false
    @State private var isShowingReturnDatePicker = false
    @State private var selectedPaymentMethod: PaymentMethodScreen.PaymentMethod = .cash
    @Environment(\.dismiss) var dismiss
    let car: Car  // Updated to use Car model from Models folder

    @State private var showBookingConfirmation = false
    @State private var totalAmount: String = "₱0"
    @State private var showLocationError = false
    @State private var showZeroDaysError = false
    @State private var showGCashPayment: Bool = false
    @State private var showCreditCardPayment: Bool = false
    @StateObject private var rentalManager = RentalManager.shared
    @StateObject private var purchaseHistoryManager = PurchaseHistoryManager.shared

    var rentalDays: Int {
        let calendar = Calendar.current
        let startOfPickUpDay = calendar.startOfDay(for: pickUpDate)
        let startOfReturnDay = calendar.startOfDay(for: returnDate)
        let numberOfDays = calendar.dateComponents([.day], from: startOfPickUpDay, to: startOfReturnDay).day ?? 0
        return numberOfDays
    }

    // Format number with comma separators
    func formattedAmount(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.locale = Locale(identifier: "en_PH")
        return "₱" + (formatter.string(from: NSNumber(value: amount)) ?? "0")
    }

    func calculateTotalAmount() {
        let pricePerDay = Int(car.priceAsDouble)  // Using OOP method from Car model
        let total = rentalDays * pricePerDay
        totalAmount = formattedAmount(total)
    }
    
    // Finalize booking and add to managers
    private func finalizeBooking() {
        rentalManager.addBooking(
            car: car,
            pickUpDate: pickUpDate,
            returnDate: returnDate,
            location: selectedAddress
        )

        let cleanAmount = totalAmount.replacingOccurrences(of: "₱", with: "").replacingOccurrences(of: ",", with: "")
        purchaseHistoryManager.addPurchase(
            paymentMethod: selectedPaymentMethod.rawValue,
            carName: car.name,
            totalAmount: cleanAmount
        )
        
        // Save booking to Firestore
        saveBookingToFirestore(cleanAmount: cleanAmount)

        showBookingConfirmation = true
    }
    
    // Save booking data to Firestore
    private func saveBookingToFirestore(cleanAmount: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user, skipping Firestore booking sync")
            return
        }
        
        let db = Firestore.firestore()
        let bookingData: [String: Any] = [
            "carName": car.name,
            "carCategory": car.category,
            "carPricePerDay": car.pricePerDay,
            "pickUpDate": Timestamp(date: pickUpDate),
            "returnDate": Timestamp(date: returnDate),
            "location": selectedAddress,
            "totalAmount": cleanAmount,
            "rentalDays": rentalDays,
            "paymentMethod": selectedPaymentMethod.rawValue,
            "bookingDate": Timestamp(date: Date())
        ]
        
        db.collection("users").document(userId).collection("bookings").addDocument(data: bookingData) { error in
            if let error = error {
                print("Error saving booking to Firestore: \(error.localizedDescription)")
            } else {
                print("Booking successfully saved to Firestore")
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.03, green: 0.11, blue: 0.26)
                    .edgesIgnoringSafeArea(.all)

                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .bold))
                        }
                        Spacer()
                        Text("Booking")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 15) {
                        Text("Pick-Up Date:")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .semibold))

                        HStack {
                            TextField("Select Date & Time", text: .constant(pickUpDate.formatted(date: .abbreviated, time: .shortened)))
                                .disabled(true)
                                .foregroundColor(.black)
                            Button(action: { isShowingPickUpDatePicker.toggle() }) {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .popover(isPresented: $isShowingPickUpDatePicker) {
                            VStack {
                                DatePicker("Pick-Up Date", selection: $pickUpDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.wheel)
                                    .labelsHidden()
                                    .padding()
                                Button("Done") {
                                    isShowingPickUpDatePicker = false
                                    calculateTotalAmount()
                                }
                                .padding()
                            }
                        }

                        Text("Return Date:")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .semibold))

                        HStack {
                            TextField("Select Date & Time", text: .constant(returnDate.formatted(date: .abbreviated, time: .shortened)))
                                .disabled(true)
                                .foregroundColor(.black)
                            Button(action: { isShowingReturnDatePicker.toggle() }) {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .popover(isPresented: $isShowingReturnDatePicker) {
                            VStack {
                                DatePicker("Return Date", selection: $returnDate, in: pickUpDate..., displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.wheel)
                                    .labelsHidden()
                                    .padding()
                                Button("Done") {
                                    isShowingReturnDatePicker = false
                                    calculateTotalAmount()
                                }
                                .padding()
                            }
                        }

                        Text("Location:")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .semibold))

                        Button(action: {
                            showMapPicker = true
                        }) {
                            ZStack {
                                // Map preview background
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.green.opacity(0.3),
                                                Color.blue.opacity(0.4),
                                                Color.green.opacity(0.2)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(height: 60)
                                
                                // Map-like grid pattern
                                VStack(spacing: 8) {
                                    HStack(spacing: 12) {
                                        ForEach(0..<5) { _ in
                                            Circle()
                                                .fill(Color.white.opacity(0.3))
                                                .frame(width: 4, height: 4)
                                        }
                                    }
                                    HStack(spacing: 15) {
                                        ForEach(0..<4) { _ in
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.white.opacity(0.2))
                                                .frame(width: 20, height: 2)
                                        }
                                    }
                                }
                                .opacity(0.6)
                                
                                // Content overlay
                                HStack {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.red)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        if selectedAddress.isEmpty {
                                            Text("Tap to select pickup location")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white)
                                            Text("Choose location on map")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white.opacity(0.8))
                                        } else {
                                            Text("Pickup Location")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white.opacity(0.8))
                                            Text(selectedAddress)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white)
                                                .lineLimit(2)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .sheet(isPresented: $showMapPicker) {
                            LocationPickerView(
                                selectedCoordinate: $selectedCoordinate,
                                selectedAddress: $selectedAddress,
                                showMapPicker: $showMapPicker
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Selected Amount:")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .semibold))
                            Spacer()
                            Text("Total:")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .semibold))
                        }

                        HStack {
                            Text("\(car.pricePerDay) x \(rentalDays) Days")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                            Spacer()
                            Text(totalAmount)
                                .foregroundColor(.white)
                                .font(.system(size: 24, weight: .bold))
                        }

                        Text("Payment Method:")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .semibold))
                        
                        NavigationLink(destination: PaymentMethodScreen(
                            selectedPaymentMethod: $selectedPaymentMethod,
                            amount: totalAmount,
                            carName: car.name
                        )) {
                            HStack {
                                Text(selectedPaymentMethod.rawValue)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Spacer()

                    Button(action: {
                        if selectedAddress.isEmpty {
                            showLocationError = true
                        } else if rentalDays <= 0 {
                            showZeroDaysError = true
                        } else {
                            // If payment method requires online flow, show payment sheet first
                            if selectedPaymentMethod == .gcash {
                                showGCashPayment = true
                            } else if selectedPaymentMethod == .creditCard {
                                showCreditCardPayment = true
                            } else {
                                // Cash: proceed immediately
                                finalizeBooking()
                            }
                        }
                     }) {
                         Text("Confirm Booking")
                             .font(.system(size: 24, weight: .bold))
                             .foregroundColor(.white)
                             .frame(maxWidth: .infinity)
                             .padding()
                             .background(Color(red: 0.25, green: 0.45, blue: 1.0))
                             .cornerRadius(15)
                     }
                     .padding(.horizontal, 20)
                     .padding(.bottom, 40)
                     .sheet(isPresented: $showGCashPayment) {
                        GCashPaymentScreen(amount: totalAmount, carName: car.name) {
                            // onSuccess: finalize booking and dismiss payment sheet
                            finalizeBooking()
                            showGCashPayment = false
                        }
                     }
                     .sheet(isPresented: $showCreditCardPayment) {
                        CreditCardPaymentScreen(amount: totalAmount, carName: car.name) {
                            finalizeBooking()
                            showCreditCardPayment = false
                        }
                     }
                     .alert("✅ Booking Successful", isPresented: $showBookingConfirmation) {
                         Button("OK", role: .cancel) {
                             dismiss()
                         }
                     } message: {
                         Text("Your booking has been confirmed successfully!")
                     }
                     .alert("Location Required", isPresented: $showLocationError) {
                         Button("OK", role: .cancel) { }
                     } message: {
                         Text("Please enter a pick-up location to proceed with the booking.")
                     }
                     .alert("Invalid Dates", isPresented: $showZeroDaysError) {
                         Button("OK", role: .cancel) { }
                     } message: {
                         Text("Pick-up and return dates must be different. Please select valid dates.")
                     }
                }
                .navigationBarHidden(true)
            }
            .onAppear { calculateTotalAmount() }
            .onChange(of: pickUpDate) { _, _ in calculateTotalAmount() }
            .onChange(of: returnDate) { _, _ in calculateTotalAmount() }
        }
    }
}

struct BookingScreen_Previews: PreviewProvider {
    static var previews: some View {
        BookingScreen(
            car: Car(
                name: "Chevrolet Camaro",
                pricePerDay: "₱6,800",
                imageName: "chevrolet-camaro",
                rating: 4,
                category: "Sports"
            )
        )
    }
}
