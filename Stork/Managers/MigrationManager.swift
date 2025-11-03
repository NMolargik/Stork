import Foundation
import Observation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Progress state for the UI
enum MigrationStatus: Equatable {
    case idle
    case preparing(String)
    case running(String, Double) // message, progress 0...1
    case completed
    case failed(String)
}

// MARK: - Firebase-backed implementation
@Observable
final class MigrationManager {
    let auth: Auth
    private let firestore: Firestore

    // Exposed for the view
    var status: MigrationStatus = .idle
    var isAuthenticated: Bool { auth.currentUser != nil }
    var currentUserId: String? { auth.currentUser?.uid }

    public init() {
        self.auth = Auth.auth()
        self.firestore = Firestore.firestore()
    }

    // MARK: - Status helpers
    private func setStatus(_ message: String, progress: Double? = nil) {
        if let p = progress {
            status = .running(message, max(0, min(1, p)))
        } else {
            status = .preparing(message)
        }
    }

    // MARK: - Main migration
    func performMigration(userManager: UserManager, deliveryManager: DeliveryManager) async throws {
        guard let userId = currentUserId else {
            status = .failed("No authenticated user.")
            throw AuthError.loginFailed("No authenticated user.")
        }

        // 1) Fetch user from Firebase
        setStatus("Fetching your profile…")
        let fbUser = try await getUser(byId: userId)

        // 2) Save into SwiftData
        await MainActor.run {
            setStatus("Saving profile to iCloud…", progress: 0.05)
            userManager.createOrReplace(newUser: fbUser)
        }

        // 3) Fetch deliveries (+ babies inside each doc)
        setStatus("Fetching deliveries…", progress: 0.10)
        let fbDeliveries = try await fetchUsersDeliveries(userId: userId)

        // 4) Save deliveries (and their babies) into SwiftData
        let total = max(1, fbDeliveries.count)
        for (idx, delivery) in fbDeliveries.enumerated() {
            // Ensure babies point back to their delivery before insert
            for b in (delivery.babies ?? []) { b.delivery = delivery }
            await MainActor.run {
                deliveryManager.create(delivery: delivery, reviewScene: nil)
            }
            let p = 0.10 + (0.70 * Double(idx + 1) / Double(total))
            setStatus("Migrating deliveries (\(idx + 1)/\(total))…", progress: p)
        }

        // 5) Delete migrated deliveries from Firebase
        for (idx, d) in fbDeliveries.enumerated() {
            try await deleteDelivery(delivery: d)
            let p = 0.80 + (0.15 * Double(idx + 1) / Double(max(1, fbDeliveries.count)))
            setStatus("Cleaning up Firebase (\(idx + 1)/\(fbDeliveries.count))…", progress: p)
        }

        // 6) Sign user out
        do {
            // Sign out the user
            try await deleteUser(user: fbUser)
            try await self.signOutUser()
        } catch {
            // Not fatal—surface a message and continue
            status = .preparing("Couldn’t delete your profile document in Firebase: \(error.localizedDescription). You can retry later.")
        }
        
        // 7) Done
        status = .completed
    }

    // MARK: - Existing helpers (unchanged)
    func getUser(byId id: String) async throws -> User {
        do {
            let document = try await firestore.collection("Profile").document(id).getDocument()
            guard let data = document.data() else {
                throw UserError.fetchFailed("Profile with ID: \(id) not found")
            }
            guard let user = User(from: data) else {
                throw UserError.fetchFailed("Invalid data for user with ID: \(id)")
            }
            print("Successfully fetched user with ID: \(id)")
            return user
        } catch {
            throw UserError.fetchFailed("Failed to fetch profile with ID: \(id): \(error.localizedDescription)")
        }
    }

    func deleteUser(user: User) async throws {
        do {
            try await firestore.collection("Profile").document(user.id.uuidString).delete()
            print("Successfully deleted user with ID: \(user.id)")
        } catch {
            throw UserError.deletionFailed("Failed to delete user with ID \(user.id): \(error.localizedDescription)")
        }
    }

    func logInUserWithEmail(emailAddress: String, password: String) async throws {
        do {
            let _ = try await auth.signIn(withEmail: emailAddress, password: password)
            print("Successfully logged in with email")
            return
        } catch {
            throw AuthError.loginFailed("Failed to login with email: \(error.localizedDescription)")
        }
    }

    func reauthenticateUser(emailAddress: String, password: String) async throws {
        guard let user = auth.currentUser else {
            throw AuthError.reauthenticationFailed("No current user found. Cannot re-authenticate.")
        }
        guard let email = user.email else {
            throw AuthError.reauthenticationFailed("Current user has no email; cannot re-authenticate.")
        }

        let credential: AuthCredential = EmailAuthProvider.credential(withEmail: email, password: password)

        do {
            try await user.reauthenticate(with: credential)
        } catch {
            throw AuthError.reauthenticationFailed("Failed to re-authenticate user: \(error.localizedDescription)")
        }
    }

    func sendPasswordReset(emailAddress: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: emailAddress)
            print("Password reset email sent.")
        } catch {
            throw AuthError.passwordResetFailed("Failed to send password reset: \(error.localizedDescription)")
        }
    }

    func signOutUser() async throws {
        do {
            try auth.signOut()
            print("User signed out!")
        } catch {
            throw AuthError.signOutFailed("Error signing out: \(error.localizedDescription)")
        }
    }

    func deleteUser(password: String) async throws {
        guard let user = auth.currentUser else {
            throw AuthError.deletionFailed("No current user found. Cannot delete.")
        }
        guard let email = user.email else {
            throw AuthError.deletionFailed("Current user has no email. Cannot re-authenticate.")
        }

        let credential: AuthCredential = EmailAuthProvider.credential(withEmail: email, password: password)
        do {
            try await user.reauthenticate(with: credential)
        } catch {
            throw AuthError.deletionFailed("Re-authentication failed: \(error.localizedDescription)")
        }

        do {
            try await user.delete()
            print("User deleted from Auth.")
        } catch {
            throw AuthError.deletionFailed("Failed to delete user from Auth: \(error.localizedDescription)")
        }
    }

    func fetchUsersDeliveries(userId: String) async throws -> [Delivery] {
        do {
            print("listDeliveries called with arguments: userId=\(String(describing: userId))")

            var query: Query = firestore.collection("Delivery").order(by: "date", descending: true)
            var filterDescriptions = [String]()

            query = query.whereField("userId", isEqualTo: userId)
            filterDescriptions.append("userId == \(userId)")
            print("About to query. Filters applied: \(filterDescriptions.joined(separator: ", "))")

            let snapshot = try await query.getDocuments()
            print("Got \(snapshot.documents.count) documents")

            let deliveries: [Delivery] = snapshot.documents.compactMap { document in
                Delivery(from: document.data(), id: document.documentID)
            }
            print("Converted deliveries to \(deliveries.count) Delivery objects")
            return deliveries
        } catch {
            throw DeliveryError.firebaseError("Failed to fetch deliveries: \(error.localizedDescription)")
        }
    }

    func deleteDelivery(delivery: Delivery) async throws {
        do {
            try await firestore.collection("Delivery").document(delivery.id.uuidString).delete()
            print("Successfully deleted delivery with id: \(delivery.id.uuidString)")
        } catch {
            throw DeliveryError.firebaseError("Failed to delete delivery: \(error.localizedDescription)")
        }
    }
}
