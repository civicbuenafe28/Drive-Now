//
//  PaymentMethodScreen.swift
//  DriveNow
//
//  Created by STUDENT on 9/17/25.
//

import SwiftUI

// MARK: - Payment Method Screen
struct PaymentMethodScreen: View {
    // Binding to the selected payment method in BookingScreen
    @Binding var selectedPaymentMethod: PaymentMethod
    
    // Environment object for navigation
    @Environment(\.presentationMode) var presentationMode
    
    // Purchase history manager
    @StateObject private var purchaseHistoryManager = PurchaseHistoryManager.shared
    
    // Payment details for sandbox
    let amount: String
    let carName: String
    
    // Enum for Payment Methods
    enum PaymentMethod: String, CaseIterable, Identifiable {
        case cash = "Cash"
        case gcash = "GCash"
        case creditCard = "Credit Card"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .cash: return "dollarsign.circle"
            case .gcash: return "g.circle.fill"
            case .creditCard: return "creditcard"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background
                Color(red: 0.03, green: 0.11, blue: 0.26)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: - Navigation Bar
                    HStack {
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.white)
                                .font(.system(size: 24, weight: .bold))
                        }
                        .padding(.leading, 20)
                        
                        Spacer()
                    }
                    .padding(.top, 50)
                    .padding(.bottom, 20)
                    
                    // MARK: - Logo
                    HStack(alignment: .center) {
                        Spacer()
                        Image("logo-white")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200)
                        Spacer()
                    }
                    .padding(.bottom, 30)
                    
                    // MARK: - Title (Centered)
                    HStack {
                        Spacer()
                        Text("Payment Method")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // MARK: - Payment Options
                    VStack(spacing: 15) {
                        ForEach(PaymentMethod.allCases) { method in
                            PaymentMethodButton(
                                method: method,
                                selected: self.selectedPaymentMethod == method
                            ) {
                                handlePaymentSelection(method)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .opacity(0.7)
                    
                    // MARK: - Purchase Log History Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Spacer()
                            Text("Purchase Log History")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 30)
                        
                        if purchaseHistoryManager.purchaseHistory.isEmpty {
                            // Empty state
                            VStack(spacing: 10) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text("No purchase history yet")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text("Your completed bookings will appear here")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            // Purchase history list
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(purchaseHistoryManager.purchaseHistory) { purchase in
                                        PurchaseHistoryRow(purchase: purchase)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                            }
                            .frame(maxHeight: 300) // Limit height to make it scrollable
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Reload purchase history when screen appears to ensure fresh data
                purchaseHistoryManager.reloadPurchaseHistoryForCurrentUser()
            }
            // Note: GCash and Credit Card selection no longer open immediate payment sheets.
            // Selection will be highlighted and the screen will dismiss back to BookingScreen.
        }
    }
    
    private func handlePaymentSelection(_ method: PaymentMethod) {
        // Mark selection and navigate back to BookingScreen. The booking confirmation
        // flow (including showing any slider) should be handled by BookingScreen when
        // the user presses Confirm Booking.
        self.selectedPaymentMethod = method
        self.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Purchase History Row
struct PurchaseHistoryRow: View {
    let purchase: PurchaseHistoryItem
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: purchase.date)
    }
    
    private var formattedAmount: String {
        // Format the amount with comma separators
        let cleanAmount = purchase.totalAmount.replacingOccurrences(of: ",", with: "")
        if let amount = Int(cleanAmount) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = ","
            formatter.locale = Locale(identifier: "en_PH")
            return "₱" + (formatter.string(from: NSNumber(value: amount)) ?? purchase.totalAmount)
        }
        return "₱\(purchase.totalAmount)"
    }
    
    private var paymentMethodIcon: String {
        switch purchase.paymentMethod {
        case "Cash": return "dollarsign.circle"
        case "GCash": return "g.circle.fill"
        case "Credit Card": return "creditcard"
        default: return "questionmark.circle"
        }
    }
    
    private var paymentMethodColor: Color {
        switch purchase.paymentMethod {
        case "Cash": return .green
        case "GCash": return .blue
        case "Credit Card": return .orange
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Payment method icon and name
                HStack(spacing: 8) {
                    Image(systemName: paymentMethodIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(paymentMethodColor)
                    
                    Text(purchase.paymentMethod)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Total amount with comma formatting
                Text(formattedAmount)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
            }
            
            // Car name
            Text(purchase.carName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            HStack {
                // Date
                Text(formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                // Transaction ID
                Text("ID: \(purchase.transactionID)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Payment Method Button
struct PaymentMethodButton: View {
    let method: PaymentMethodScreen.PaymentMethod
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: method.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(method.rawValue)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(selected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selected ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview Provider
struct PaymentMethodScreen_Previews: PreviewProvider {
    static var previews: some View {
        PaymentMethodScreen(selectedPaymentMethod: .constant(.cash), amount: "100", carName: "Sedan")
    }
}
