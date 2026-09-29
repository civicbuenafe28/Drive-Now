//
//  CreditCardPaymentScreen.swift
//  DriveNow
//
//  Created by STUDENT on 10/2/25.
//

import SwiftUI

struct CreditCardPaymentScreen: View {
    @Environment(\.dismiss) var dismiss
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var cardholderName = ""
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var transactionId = ""
    
    let amount: String
    let carName: String
    // Optional callback to notify caller of successful payment
    var onSuccess: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Credit card gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.3),
                    Color(red: 0.2, green: 0.2, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .bold))
                        }
                        Spacer()
                        Text("Credit Card Payment")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Credit Card Icon
                    Image(systemName: "creditcard")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Payment Details
                    VStack(spacing: 10) {
                        Text("Payment for: \(carName)")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(amount)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 20)
                    
                    // Credit Card Form
                    VStack(spacing: 15) {
                        // Card Number
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Card Number")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            TextField("1234 5678 9012 3456", text: $cardNumber)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: cardNumber) { oldValue, newValue in
                                    // Format card number with spaces
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered.count <= 16 {
                                        let formatted = formatCardNumber(filtered)
                                        cardNumber = formatted
                                    } else {
                                        cardNumber = String(newValue.dropLast())
                                    }
                                }
                        }
                        
                        // Cardholder Name
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Cardholder Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            TextField("John Doe", text: $cardholderName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                        }
                        
                        // Expiry and CVV
                        HStack(spacing: 15) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Expiry Date")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                
                                TextField("MM/YY", text: $expiryDate)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: expiryDate) { oldValue, newValue in
                                        expiryDate = formatExpiryDate(newValue)
                                    }
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("CVV")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                
                                SecureField("123", text: $cvv)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: cvv) { oldValue, newValue in
                                        if newValue.count > 3 {
                                            cvv = String(newValue.prefix(3))
                                        }
                                    }
                            }
                        }
                        
                        // Pay Button
                        Button(action: {
                            processPayment()
                        }) {
                            if isProcessing {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Processing Payment...")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.7))
                                .cornerRadius(10)
                            } else {
                                Text("Pay \(amount)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(10)
                            }
                        }
                        .disabled(!isFormValid || isProcessing)
                        .opacity(isFormValid && !isProcessing ? 1.0 : 0.6)
                        .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                    
                    // Security Notice
                    VStack(spacing: 5) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.white.opacity(0.7))
                            Text("Secured by 256-bit SSL encryption")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Text("Your payment information is protected and secure")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        
            // Custom Success Dialog Overlay
            if showSuccess {
                ZStack {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 20) {
                        // Circular Checkmark
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        // Success Title
                        Text("Payment Successful!")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                        
                        VStack(spacing: 12) {
                            // Cardholder Name
                            HStack {
                                Text("Cardholder:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(cardholderName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            
                            // Date Purchased
                            HStack {
                                Text("Date:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(Date().formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            
                            // Payment For
                            HStack {
                                Text("Payment for:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(carName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            
                            // Total Amount
                            HStack {
                                Text("Total Amount:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(amount)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            
                            Divider()
                            
                            // Transaction ID
                            HStack {
                                Text("Transaction ID:")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(transactionId)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(.horizontal)
                        
                        // OK Button
                        Button(action: {
                            showSuccess = false
                            // Notify caller (BookingScreen) that payment succeeded
                            onSuccess?()
                            dismiss()
                        }) {
                            Text("OK")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 20)
                    .padding(.horizontal, 40)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !cardNumber.isEmpty &&
        !cardholderName.isEmpty &&
        !expiryDate.isEmpty &&
        !cvv.isEmpty &&
        cardNumber.replacingOccurrences(of: " ", with: "").count == 16 &&
        expiryDate.count == 5 &&
        cvv.count == 3
    }
    
    private func formatCardNumber(_ number: String) -> String {
        var formatted = ""
        for (index, character) in number.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(character)
        }
        return formatted
    }
    
    private func formatExpiryDate(_ date: String) -> String {
        let filtered = date.filter { $0.isNumber }
        if filtered.count <= 2 {
            return filtered
        } else if filtered.count <= 4 {
            let month = String(filtered.prefix(2))
            let year = String(filtered.dropFirst(2))
            return "\(month)/\(year)"
        } else {
            return String(date.dropLast())
        }
    }
    
    private func processPayment() {
        isProcessing = true
        
        // Simulate payment processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isProcessing = false
            transactionId = "CC\(Int.random(in: 1000000...9999999))"
            showSuccess = true
        }
    }
}

struct CreditCardPaymentScreen_Previews: PreviewProvider {
    static var previews: some View {
        CreditCardPaymentScreen(amount: "₱7,500", carName: "Honda Civic", onSuccess: nil)
    }
}
