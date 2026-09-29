//
//  GettingStartedScreen.swift
//  DriveNow
//
//  Created by STUDENT on 8/27/25.
//

import SwiftUI

struct GettingStartedScreen: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.03, green: 0.11, blue: 0.26)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    ZStack {
                        Image("mercedes-gwagon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: UIScreen.main.bounds.height * 1.00)
                            .offset(y: 1)

                        Image("ferrari")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: UIScreen.main.bounds.height * 0.45)
                            .offset(y: 150)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)

                    VStack(alignment: .leading, spacing: 20) {
                        Text("Experience like never before")
                            .font(.system(size: 40).weight(.black))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.7)
                            .lineLimit(2)

                        Text("Choose a car and begin your driving experience today!")
                            .font(.system(size: 15).weight(.bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.8)
                            .lineLimit(2)

                        Spacer()

                        NavigationLink(destination: LoginSignUpScreen()) {
                            Text("Get Started")
                                .font(.system(size: 24).weight(.bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(.white)
                                .cornerRadius(15)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 80)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    GettingStartedScreen()
        .environmentObject(AuthViewModel.preview)
}
