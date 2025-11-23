//
//  LoginLoadingScreen.swift
//  DriveNow
//
//  Created by STUDENT on 10/7/25.
//

import SwiftUI

struct LoginLoadingScreen: View {
    @State private var isLoading = false
    @State private var rotationAngle: Double = 0
    @State private var scale: Double = 1.0

    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var shouldNavigateToHome = false

    var body: some View {
        ZStack {
            // Background with same color as login screen
            Color(red: 0.03, green: 0.11, blue: 0.26)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {
                // Logo in the center
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: scale)

                // Loading text
                Text("Logging in...")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)

                // Loading animation - rotating circles
                HStack(spacing: 10) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                            .scaleEffect(isLoading ? 1.0 : 0.5)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: isLoading
                            )
                    }
                }
            }
        }
        .onAppear {
            // Start animations
            isLoading = true
            scale = 1.2

            // Navigate to HomeTab after a shorter delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                shouldNavigateToHome = true
            }
        }
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $shouldNavigateToHome) {
            HomeTab()
        }
    }
}

#Preview {
    LoginLoadingScreen()
        .environmentObject(AuthViewModel.preview)
}
