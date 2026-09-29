//
//  GCashPaymentScreen.swift
//  DriveNow
//
//  Created by STUDENT on 10/2/25.
//

import SwiftUI

struct GCashPaymentScreen: View {
    @Environment(\.dismiss) var dismiss
    @State private var mobileNumber = ""
    @State private var pin = ""
    @State private var showingPinField = false
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var transactionId = ""
    
    let amount: String
    let carName: String
    // Optional callback to notify caller of successful payment
    var onSuccess: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // GCash blue background
            Color(red: 0.0, green: 0.4, blue: 0.8)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                    }
                    Spacer()
                    Text("GCash Payment")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // GCash Logo
                Image(systemName: "g.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Text("GCash")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                // Payment Details
                VStack(spacing: 10) {
                    Text("Payment for: \(carName)")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(amount)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 20)
                
                // Payment Form
                VStack(spacing: 15) {
                    if !showingPinField {
                        // Mobile Number Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mobile Number")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("+63")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                
                                TextField("9XX XXX XXXX", text: $mobileNumber)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: mobileNumber) { oldValue, newValue in
                                        // Format mobile number as user types
                                        if newValue.count > 10 {
                                            mobileNumber = String(newValue.prefix(10))
                                        }
                                    }
                            }
                        }
                        
                        Button(action: {
                            if mobileNumber.count == 10 {
                                showingPinField = true
                            }
                        }) {
                            Text("Continue")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                        .disabled(mobileNumber.count != 10)
                        .opacity(mobileNumber.count == 10 ? 1.0 : 0.6)
                        
                    } else {
                        // PIN Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enter your GCash PIN")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            SecureField("6-digit PIN", text: $pin)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: pin) { oldValue, newValue in
                                    if newValue.count > 6 {
                                        pin = String(newValue.prefix(6))
                                    }
                                }
                        }
                        
                        Button(action: {
                            processPayment()
                        }) {
                            if isProcessing {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                    Text("Processing...")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.blue)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                            } else {
                                Text("Pay Now")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                            }
                        }
                        .disabled(pin.count != 6 || isProcessing)
                        .opacity(pin.count == 6 && !isProcessing ? 1.0 : 0.6)
                        
                        Button(action: {
                            showingPinField = false
                            pin = ""
                        }) {
                            Text("Back")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Security Notice
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.white.opacity(0.7))
                    Text("Your payment is secured with GCash")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 40)
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
                            // GCash Number
                            HStack {
                                Text("GCash Number:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("+63\(mobileNumber)")
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
                                .background(Color.blue)
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
    
    private func processPayment() {
        isProcessing = true
        
        // Simulate payment processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isProcessing = false
            transactionId = "GC\(Int.random(in: 100000...999999))"
            showSuccess = true
        }
    }
}

struct GCashPaymentScreen_Previews: PreviewProvider {
    static var previews: some View {
        GCashPaymentScreen(amount: "₱7,500", carName: "Honda Civic", onSuccess: nil)
    }
}
