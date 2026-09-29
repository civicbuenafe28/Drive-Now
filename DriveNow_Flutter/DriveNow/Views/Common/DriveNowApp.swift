//
//  DriveNowApp.swift
//  DriveNow
//
//  Created by STUDENT on 10/7/25.
//

import SwiftUI
import Firebase

@main
struct DriveNowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Use a StateObject for the Firebase auth view model and inject into environment
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    print("Connected to Firebase")

    return true
  }
}
