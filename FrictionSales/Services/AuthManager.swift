import Foundation
import FirebaseAuth
import Combine

class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated: Bool = false
    
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        self.authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func signInAnonymously() async throws {
        do {
            let result = try await Auth.auth().signInAnonymously()
            print("Signed in anonymously with uid: \(result.user.uid)")
        } catch {
            print("Error signing in anonymously: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signInWithEmail(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            print("Signed in with email: \(result.user.email ?? "")")
        } catch {
            print("Error signing in: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signUpWithEmail(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            print("Signed up with email: \(result.user.email ?? "")")
        } catch {
            print("Error signing up: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateEmail(to newEmail: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No signed-in user found."])
        }
        do {
            try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
            print("Successfully requested email update verification")
        } catch {
            print("Error updating email: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updatePassword(to newPassword: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No signed-in user found."])
        }
        do {
            try await user.updatePassword(to: newPassword)
            print("Successfully updated password")
        } catch {
            print("Error updating password: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            print("Successfully signed out")
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No signed-in user found."])
        }
        do {
            try await user.delete()
            print("Successfully deleted account")
        } catch {
            print("Error deleting account: \(error.localizedDescription)")
            throw error
        }
    }
}
