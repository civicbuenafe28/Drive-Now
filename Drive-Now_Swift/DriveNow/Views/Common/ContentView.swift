    //
//  ContentView.swift
//  DriveNow
//
//  Created by STUDENT on 8/27/25.
//

// ContentView.swift

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    // State to manage the splash screen flow
    @State private var screenState = 0

    // Use environment auth view model instead of binding (kept for future use if needed)
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Monitor user data in Firestore
    @ObservedObject private var userDataMonitor = UserDataMonitor.shared

    // Show LoginSignUpScreen directly if coming from account deletion
    @State private var shouldShowLoginDirectly = false

    var body: some View {
        ZStack {
            if screenState == 0 {
                // MARK: - Flash Screen 1
                Image("logo-blue")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { screenState = 1 }
                        }
                    }
            } else if screenState == 1 {
                // MARK: - Flash Screen 2
                Image("logo-white")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(red: 0.1, green: 0.2, blue: 0.4))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation(.easeInOut(duration: 0.5)) { screenState = 2 }
                        }
                    }
            } else if screenState == 2 {
                // MARK: - Main App Flow
                // Exact required flow after splash:
                // - If triggered by account deletion -> LoginSignUpScreen
                // - Otherwise -> GettingStartedScreen
                if shouldShowLoginDirectly {
                    LoginSignUpScreen()
                        .transition(.move(edge: .trailing))
                } else {
                    GettingStartedScreen()
                        .transition(.move(edge: .trailing))
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            // Start monitoring when user is authenticated
            if authViewModel.isAuthenticated {
                userDataMonitor.startListening()
            }
        }
        .onDisappear {
            userDataMonitor.stopListening()
        }
        .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
            if newValue {
                // User logged in - start monitoring
                userDataMonitor.startListening()
                
                // Load data from Firestore for managers
                FavoritesManager.shared.loadFromFirestore()
                PurchaseHistoryManager.shared.loadFromFirestore()
            } else {
                // User logged out - stop monitoring
                userDataMonitor.stopListening()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AccountDeleted"))) { _ in
            // Trigger showing LoginSignUpScreen immediately (e.g., after account deletion or explicit sign out flows)
            DispatchQueue.main.async {
                shouldShowLoginDirectly = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel.preview)
}
