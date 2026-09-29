import Foundation
import FirebaseAuth
import Firebase
import Combine

final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User? = nil

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        // Only attach listener if Firebase configured
        if FirebaseApp.app() != nil {
            authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
                DispatchQueue.main.async {
                    self?.currentUser = user
                    self?.isAuthenticated = (user != nil)
                }
            }
        } else {
            // For preview/development when Firebase not configured
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // Async sign in using Firebase
    func signIn(email: String, password: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                DispatchQueue.main.async {
                    self?.currentUser = result?.user
                    self?.isAuthenticated = result?.user != nil
                }
                continuation.resume(returning: ())
            }
        }
    }

    // Async sign up using Firebase
    func signUp(fullName: String, email: String, password: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
                if let error = error {
                    // Log detailed error information
                    print("Firebase sign-up error: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                // Optionally set display name
                if let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest() {
                    changeRequest.displayName = fullName
                    changeRequest.commitChanges { _ in
                        DispatchQueue.main.async {
                            self?.currentUser = Auth.auth().currentUser
                            self?.isAuthenticated = Auth.auth().currentUser != nil
                        }
                        continuation.resume(returning: ())
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.currentUser = result?.user
                        self?.isAuthenticated = result?.user != nil
                    }
                    continuation.resume(returning: ())
                }
            }
        }
    }

    // Sign out
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isAuthenticated = false
                // Notify the app to present the LoginSignUpScreen after sign out.
                // ContentView listens for "AccountDeleted" and will show LoginSignUpScreen.
                NotificationCenter.default.post(name: NSNotification.Name("AccountDeleted"), object: nil)
            }
        } catch {
            throw error
        }
    }

    // Delete account (calls Firebase delete)
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"]) 
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.delete { error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                DispatchQueue.main.async {
                    self.currentUser = nil
                    self.isAuthenticated = false
                }
                continuation.resume(returning: ())
            }
        }
    }

    // For preview/mocks
    static var preview: AuthViewModel {
        let vm = AuthViewModel()
        vm.isAuthenticated = false
        vm.currentUser = nil
        return vm
    }
}
