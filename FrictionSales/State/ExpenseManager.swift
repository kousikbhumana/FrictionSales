import Combine
import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Owns shared expense, category, profile, currency, and persistence state for the app.
final class ExpenseManager: ObservableObject {
    private static let maximumCategoryNameLength = 40
    private static let maximumNoteLength = 240
    private static let maximumProfileNameLength = 60
    private static let storageKey = "friction-expenses-v1"

    @Published private(set) var categories: [ExpenseCategory]
    @Published private(set) var transactions: [ExpenseTransaction]
    @Published private(set) var profileName: String
    @Published private(set) var currencyCode: String

    private let storage: UserDefaults?

    /// Creates shared state, loading persisted values when a storage container is supplied.
    init(
        categories: [ExpenseCategory] = ExpenseManager.defaultCategories,
        transactions: [ExpenseTransaction] = [],
        profileName: String = "My Profile",
        currencyCode: String = "USD",
        storage: UserDefaults? = .standard
    ) {
        self.storage = storage

        if let data = storage?.data(forKey: Self.storageKey),
           let state = try? JSONDecoder().decode(PersistedState.self, from: data) {
            self.categories = state.categories.isEmpty ? categories : state.categories
            self.transactions = state.transactions.sorted { $0.date > $1.date }
            self.profileName = state.profileName
            self.currencyCode = CurrencyOption.option(for: state.currencyCode).code
        } else {
            self.categories = categories
            self.transactions = transactions.sorted { $0.date > $1.date }
            self.profileName = profileName
            self.currencyCode = CurrencyOption.option(for: currencyCode).code
        }
    }

    /// The currently selected app-wide currency option.
    var selectedCurrency: CurrencyOption {
        CurrencyOption.option(for: currencyCode)
    }

    /// Validates and records an expense in reverse-chronological order.
    @discardableResult
    func recordExpense(
        amount: Double,
        category: ExpenseCategory,
        date: Date = .now,
        note: String = ""
    ) -> Bool {
        let normalizedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canRecordExpense(amount: amount, category: category, date: date, note: normalizedNote) else {
            return false
        }

        let transaction = ExpenseTransaction(
            amount: amount,
            category: category,
            date: date,
            note: normalizedNote
        )
        let insertionIndex = transactions.firstIndex(where: { $0.date < transaction.date })
            ?? transactions.endIndex
        transactions.insert(transaction, at: insertionIndex)
        persist()
        return true
    }

    /// Revalidates and replaces an existing expense while preserving its stable identifier.
    @discardableResult
    func updateExpense(
        id: UUID,
        amount: Double,
        category: ExpenseCategory,
        date: Date,
        note: String
    ) -> Bool {
        let normalizedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let transactionIndex = transactions.firstIndex(where: { $0.id == id }),
              canUpdateExpense(
                id: id,
                amount: amount,
                category: category,
                date: date,
                note: normalizedNote
              ) else {
            return false
        }

        transactions[transactionIndex] = ExpenseTransaction(
            id: id,
            amount: amount,
            category: category,
            date: date,
            note: normalizedNote
        )
        transactions.sort { $0.date > $1.date }
        persist()
        return true
    }

    /// Returns whether an existing transaction can safely accept the proposed changes.
    func canUpdateExpense(
        id: UUID,
        amount: Double,
        category: ExpenseCategory,
        date: Date,
        note: String
    ) -> Bool {
        guard let existingTransaction = transactions.first(where: { $0.id == id }) else {
            return false
        }

        let categoryIsAvailable = categories.contains(where: { $0.id == category.id })
            || existingTransaction.category.id == category.id
        return amount.isFinite
            && amount > 0
            && date <= Date.now
            && note.trimmingCharacters(in: .whitespacesAndNewlines).count <= Self.maximumNoteLength
            && categoryIsAvailable
    }

    /// Permanently removes one known expense and returns whether a transaction was deleted.
    @discardableResult
    func deleteExpense(id: UUID) -> Bool {
        guard transactions.contains(where: { $0.id == id }) else { return false }
        transactions.removeAll(where: { $0.id == id })
        persist()
        return true
    }

    /// Returns whether a transaction's amount, category, date, and note are safe to store.
    func canRecordExpense(
        amount: Double,
        category: ExpenseCategory,
        date: Date = .now,
        note: String = ""
    ) -> Bool {
        amount.isFinite
            && amount > 0
            && date <= Date.now
            && note.trimmingCharacters(in: .whitespacesAndNewlines).count <= Self.maximumNoteLength
            && categories.contains(where: { $0.id == category.id })
    }

    /// Returns expenses for one calendar day in reverse-chronological order.
    func expenses(on date: Date, calendar: Calendar = .current) -> [ExpenseTransaction] {
        transactions.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }

    /// Adds a unique custom category using one of the vetted SF Symbols.
    @discardableResult
    func addCategory(name: String, symbol: String) -> Bool {
        let normalizedName = normalizeSingleLine(name)
        guard canAddCategory(name: normalizedName, symbol: symbol) else { return false }

        categories.append(ExpenseCategory(name: normalizedName, symbol: symbol, isCustom: true))
        categories.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        persist()
        return true
    }

    /// Returns whether a custom category has a unique name and approved SF Symbol.
    func canAddCategory(name: String, symbol: String) -> Bool {
        let normalizedName = normalizeSingleLine(name)
        return !normalizedName.isEmpty
            && normalizedName.count <= Self.maximumCategoryNameLength
            && Self.availableCategorySymbols.contains(symbol)
            && !categories.contains(where: {
                $0.name.compare(
                    normalizedName,
                    options: [.caseInsensitive, .diacriticInsensitive]
                ) == .orderedSame
            })
    }

    /// Removes only a user-created category; existing transaction snapshots remain intact.
    func deleteCategory(_ category: ExpenseCategory) {
        guard category.isCustom else { return }
        categories.removeAll(where: { $0.id == category.id })
        persist()
    }

    /// Validates and saves the user's display name.
    @discardableResult
    func updateProfileName(_ name: String) -> Bool {
        let normalizedName = normalizeSingleLine(name)
        guard canUpdateProfileName(normalizedName) else {
            return false
        }
        profileName = normalizedName
        persist()
        return true
    }

    /// Returns whether a proposed profile name is nonempty and within the safe storage limit.
    func canUpdateProfileName(_ name: String) -> Bool {
        let normalizedName = normalizeSingleLine(name)
        return !normalizedName.isEmpty && normalizedName.count <= Self.maximumProfileNameLength
    }

    /// Applies a supported ISO currency code to every monetary view in the app.
    func updateCurrency(_ option: CurrencyOption) {
        guard CurrencyOption.supported.contains(option) else { return }
        currencyCode = option.code
        persist()
    }

    /// Formats an amount consistently using the selected currency's native locale and symbol.
    func formattedCurrency(_ amount: Double) -> String {
        let currency = selectedCurrency
        return amount.formatted(
            .currency(code: currency.code)
                .precision(.fractionLength(0...2))
                .locale(Locale(identifier: currency.localeIdentifier))
        )
    }

    /// Trims and collapses whitespace so persisted single-line values are canonical.
    private func normalizeSingleLine(_ value: String) -> String {
        value.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    /// Persists one compact JSON state snapshot locally and syncs to Firebase.
    private func persist() {
        guard let storage else { return }
        let state = PersistedState(
            categories: categories,
            transactions: transactions,
            profileName: profileName,
            currencyCode: currencyCode
        )
        guard let data = try? JSONEncoder().encode(state) else { return }
        storage.set(data, forKey: Self.storageKey)
        
        // Sync to Firebase in the background
        syncToFirebase(state: state)
    }
    
    // MARK: - Firebase Sync
    
    /// Uploads the current snapshot to Firestore under the user's UID
    private func syncToFirebase(state: PersistedState) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Convert to dictionary for Firestore
        guard let data = try? JSONEncoder().encode(state),
              let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else { return }
        
        Firestore.firestore().collection("users").document(uid).setData(dict) { error in
            if let error = error {
                print("Error syncing to Firebase: \(error.localizedDescription)")
            } else {
                print("Successfully synced to Firebase")
            }
        }
    }
    
    /// Fetches the user's snapshot from Firestore and overwrites local data
    func fetchFromFirebase() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            let document = try await Firestore.firestore().collection("users").document(uid).getDocument()
            if let data = document.data() {
                // Convert dict back to PersistedState
                let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
                let state = try JSONDecoder().decode(PersistedState.self, from: jsonData)
                
                await MainActor.run {
                    self.categories = state.categories.isEmpty ? ExpenseManager.defaultCategories : state.categories
                    self.transactions = state.transactions.sorted { $0.date > $1.date }
                    self.profileName = state.profileName
                    self.currencyCode = CurrencyOption.option(for: state.currencyCode).code
                    // Save locally too
                    if let encoded = try? JSONEncoder().encode(state) {
                        self.storage?.set(encoded, forKey: Self.storageKey)
                    }
                }
            }
        } catch {
            print("Error fetching from Firebase: \(error.localizedDescription)")
        }
    }
    
    /// Completely erases all local data and deletes the cloud document
    func resetApp() {
        storage?.removeObject(forKey: Self.storageKey)
        
        // Reset local state to default
        self.categories = ExpenseManager.defaultCategories
        self.transactions = []
        self.profileName = "My Profile"
        self.currencyCode = "USD"
        
        // Wipe cloud data
        if let uid = Auth.auth().currentUser?.uid {
            Firestore.firestore().collection("users").document(uid).delete()
        }
    }
}

private extension ExpenseManager {
    struct PersistedState: Codable {
        let categories: [ExpenseCategory]
        let transactions: [ExpenseTransaction]
        let profileName: String
        let currencyCode: String
    }
}

extension ExpenseManager {
    /// SF Symbols offered when creating a category, all sourced from Apple's system symbol catalog.
    static let availableCategorySymbols: [String] = [
        "fork.knife", "airplane", "person.fill", "sparkles", "bag.fill", "cart.fill",
        "car.fill", "bus.fill", "fuelpump.fill", "house.fill", "doc.text.fill", "bolt.fill",
        "cross.case.fill", "pills.fill", "dumbbell.fill", "film.fill", "gamecontroller.fill",
        "book.fill", "graduationcap.fill", "gift.fill", "pawprint.fill", "cup.and.saucer.fill",
        "tshirt.fill", "scissors", "briefcase.fill", "iphone", "wifi", "leaf.fill",
        "heart.fill", "star.fill", "square.grid.2x2.fill"
    ]

    /// Starter categories available before the user adds any personal categories.
    static let defaultCategories: [ExpenseCategory] = [
        ExpenseCategory(name: "Food", symbol: "fork.knife"),
        ExpenseCategory(name: "Travel", symbol: "airplane"),
        ExpenseCategory(name: "Personal", symbol: "person.fill"),
        ExpenseCategory(name: "Beauty", symbol: "sparkles"),
        ExpenseCategory(name: "Shopping", symbol: "bag.fill"),
        ExpenseCategory(name: "Groceries", symbol: "cart.fill"),
        ExpenseCategory(name: "Transport", symbol: "car.fill"),
        ExpenseCategory(name: "Bills", symbol: "doc.text.fill"),
        ExpenseCategory(name: "Health", symbol: "cross.case.fill"),
        ExpenseCategory(name: "Fitness", symbol: "dumbbell.fill"),
        ExpenseCategory(name: "Entertainment", symbol: "film.fill"),
        ExpenseCategory(name: "Education", symbol: "book.fill"),
        ExpenseCategory(name: "Home", symbol: "house.fill"),
        ExpenseCategory(name: "Gifts", symbol: "gift.fill"),
        ExpenseCategory(name: "Other", symbol: "square.grid.2x2.fill")
    ]

    /// A realistic, isolated manager used by previews without touching on-device storage.
    static var previewPopulated: ExpenseManager {
        let categories = defaultCategories
        let calendar = Calendar.current
        let samples: [(String, Double, Int, String)] = [
            ("Food", 145, 0, "Dinner with the design team"),
            ("Travel", 82.40, -1, "Airport ride"),
            ("Beauty", 64, -3, "Hair appointment"),
            ("Groceries", 118.75, -7, "Weekly groceries"),
            ("Bills", 210, -12, "Electricity and internet"),
            ("Shopping", 96, -31, "Work essentials"),
            ("Travel", 430, -45, "Weekend flights"),
            ("Food", 72, -63, "Birthday lunch")
        ]

        let transactions = samples.compactMap { name, amount, dayOffset, note -> ExpenseTransaction? in
            guard let category = categories.first(where: { $0.name == name }),
                  let date = calendar.date(byAdding: .day, value: dayOffset, to: .now) else {
                return nil
            }
            return ExpenseTransaction(amount: amount, category: category, date: date, note: note)
        }

        return ExpenseManager(
            categories: categories,
            transactions: transactions,
            profileName: "Alex Morgan",
            currencyCode: "USD",
            storage: nil
        )
    }
}
