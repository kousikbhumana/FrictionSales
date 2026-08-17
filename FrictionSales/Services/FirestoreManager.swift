import Foundation
import FirebaseFirestore
import Combine

class FirestoreManager: ObservableObject {
    private let db = Firestore.firestore()
    
    // Example: Save a generic record to a collection
    func saveRecord(collection: String, documentId: String? = nil, data: [String: Any]) async throws {
        do {
            if let id = documentId {
                try await db.collection(collection).document(id).setData(data)
            } else {
                let _ = try await db.collection(collection).addDocument(data: data)
            }
            print("Successfully saved record to \(collection)")
        } catch {
            print("Error saving record: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Example: Fetch all records from a collection
    func fetchRecords(collection: String) async throws -> [[String: Any]] {
        do {
            let snapshot = try await db.collection(collection).getDocuments()
            return snapshot.documents.map { $0.data() }
        } catch {
            print("Error fetching records: \(error.localizedDescription)")
            throw error
        }
    }
}
