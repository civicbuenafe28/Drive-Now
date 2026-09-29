//
//  LoginSignUpScreen.swift
//  DriveNow
//
//  Created by STUDENT on 8/27/25.
//

import SwiftUI

struct LoginSignUpScreen: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.03, green: 0.11, blue: 0.26)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 30) {
                    Spacer()

                    Image("logoonly-white")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)

                    Spacer()

                    VStack(spacing: 15) {
                        NavigationLink(destination: LoginScreen()) {
                            Text("Log In")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.25, green: 0.45, blue: 1.0))
                                .cornerRadius(15)
                        }
                        .padding(.horizontal, 20)

                        NavigationLink(destination: SignUpScreen()) {
                            Text("Sign Up")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(red: 0.03, green: 0.11, blue: 0.26))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.85, green: 0.85, blue: 0.85))
                                .cornerRadius(15)
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer()

                    Text("©2025 Buenafe Inc. All Rights Reserved")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    LoginSignUpScreen()
        .environmentObject(AuthViewModel.preview)
}
