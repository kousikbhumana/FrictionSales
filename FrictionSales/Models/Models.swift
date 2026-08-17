import Foundation

/// Calendar scopes available in the Stats calendar workspace.
enum ExpenseTimeframe: String, CaseIterable, Identifiable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case yearToDate = "YTD"
    case custom = "Custom"
    case allTime = "All Time"

    var id: Self { self }

    /// Scopes that users can select in the calendar analytics page.
    static let calendarOptions: [ExpenseTimeframe] = [
        .today,
        .thisWeek,
        .thisMonth,
        .yearToDate,
        .custom
    ]

    /// A compact label that remains readable on smaller iPhones.
    var compactTitle: String {
        switch self {
        case .today: "Today"
        case .thisWeek: "Week"
        case .thisMonth: "Month"
        case .yearToDate: "YTD"
        case .custom: "Custom"
        case .allTime: "All"
        }
    }
}

/// A reusable expense category backed by an Apple SF Symbol.
struct ExpenseCategory: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let symbol: String
    let isCustom: Bool

    /// Creates a category with a stable identifier for persistence and analytics.
    init(id: UUID = UUID(), name: String, symbol: String, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.isCustom = isCustom
    }
}

/// An immutable snapshot of one recorded expense.
struct ExpenseTransaction: Identifiable, Hashable, Codable {
    let id: UUID
    let amount: Double
    let category: ExpenseCategory
    let date: Date
    let note: String

    /// Creates a transaction while preserving the category used when it was saved.
    init(
        id: UUID = UUID(),
        amount: Double,
        category: ExpenseCategory,
        date: Date = .now,
        note: String = ""
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.date = date
        self.note = note
    }
}

/// Aggregated expense count and value for one category.
struct CategoryPerformance: Identifiable, Hashable {
    let id: UUID
    let category: ExpenseCategory
    let expenseCount: Int
    let totalSpent: Double
}

/// Relative position of a month inside one category's lifetime spending history.
enum MonthSpendingPosition: Hashable {
    case least
    case standard
    case highest
    case tied
}

/// Count and spending recorded for one category during one calendar month.
struct MonthlyCategorySpending: Identifiable, Hashable {
    let monthStart: Date
    let expenseCount: Int
    let totalSpent: Double
    let position: MonthSpendingPosition

    var id: Date { monthStart }
}

/// Lifetime and monthly spending history for one category.
struct CategoryHistorySummary: Identifiable, Hashable {
    let id: UUID
    let category: ExpenseCategory
    let expenseCount: Int
    let totalSpent: Double
    let monthlySpending: [MonthlyCategorySpending]
}

/// A single-pass analytics snapshot for a selected period.
struct ExpenseSummary: Hashable {
    let totalSpent: Double
    let expenseCount: Int
    let categoriesBySpending: [CategoryPerformance]

    var topCategory: CategoryPerformance? { categoriesBySpending.first }
    var leastCategory: CategoryPerformance? { categoriesBySpending.last }

    static let empty = ExpenseSummary(totalSpent: 0, expenseCount: 0, categoriesBySpending: [])
}

/// The highest-spending recorded day, week, month, or quarter.
struct SpendPeriodRecord: Hashable {
    let periodLabel: String
    let totalSpent: Double
    let expenseCount: Int
}

/// A currency made available as an app-wide expense display preference.
struct CurrencyOption: Identifiable, Hashable {
    let code: String
    let symbol: String
    let localeIdentifier: String

    var id: String { code }

    /// Uses Foundation's localized ISO currency name when available.
    var displayName: String {
        Locale.current.localizedString(forCurrencyCode: code) ?? code
    }

    /// A broad, curated collection of commonly used ISO currencies and their familiar symbols.
    static let supported: [CurrencyOption] = [
        CurrencyOption(code: "USD", symbol: "$", localeIdentifier: "en_US"),
        CurrencyOption(code: "INR", symbol: "₹", localeIdentifier: "en_IN"),
        CurrencyOption(code: "EUR", symbol: "€", localeIdentifier: "de_DE"),
        CurrencyOption(code: "GBP", symbol: "£", localeIdentifier: "en_GB"),
        CurrencyOption(code: "JPY", symbol: "¥", localeIdentifier: "ja_JP"),
        CurrencyOption(code: "CNY", symbol: "¥", localeIdentifier: "zh_CN"),
        CurrencyOption(code: "KRW", symbol: "₩", localeIdentifier: "ko_KR"),
        CurrencyOption(code: "AUD", symbol: "A$", localeIdentifier: "en_AU"),
        CurrencyOption(code: "CAD", symbol: "C$", localeIdentifier: "en_CA"),
        CurrencyOption(code: "SGD", symbol: "S$", localeIdentifier: "en_SG"),
        CurrencyOption(code: "HKD", symbol: "HK$", localeIdentifier: "zh_HK"),
        CurrencyOption(code: "NZD", symbol: "NZ$", localeIdentifier: "en_NZ"),
        CurrencyOption(code: "CHF", symbol: "CHF", localeIdentifier: "de_CH"),
        CurrencyOption(code: "AED", symbol: "د.إ", localeIdentifier: "ar_AE"),
        CurrencyOption(code: "SAR", symbol: "ر.س", localeIdentifier: "ar_SA"),
        CurrencyOption(code: "QAR", symbol: "ر.ق", localeIdentifier: "ar_QA"),
        CurrencyOption(code: "KWD", symbol: "د.ك", localeIdentifier: "ar_KW"),
        CurrencyOption(code: "BHD", symbol: "د.ب", localeIdentifier: "ar_BH"),
        CurrencyOption(code: "OMR", symbol: "ر.ع", localeIdentifier: "ar_OM"),
        CurrencyOption(code: "ZAR", symbol: "R", localeIdentifier: "en_ZA"),
        CurrencyOption(code: "BRL", symbol: "R$", localeIdentifier: "pt_BR"),
        CurrencyOption(code: "MXN", symbol: "MX$", localeIdentifier: "es_MX"),
        CurrencyOption(code: "SEK", symbol: "kr", localeIdentifier: "sv_SE"),
        CurrencyOption(code: "NOK", symbol: "kr", localeIdentifier: "nb_NO"),
        CurrencyOption(code: "DKK", symbol: "kr", localeIdentifier: "da_DK"),
        CurrencyOption(code: "PLN", symbol: "zł", localeIdentifier: "pl_PL"),
        CurrencyOption(code: "CZK", symbol: "Kč", localeIdentifier: "cs_CZ"),
        CurrencyOption(code: "HUF", symbol: "Ft", localeIdentifier: "hu_HU"),
        CurrencyOption(code: "TRY", symbol: "₺", localeIdentifier: "tr_TR"),
        CurrencyOption(code: "ILS", symbol: "₪", localeIdentifier: "he_IL"),
        CurrencyOption(code: "THB", symbol: "฿", localeIdentifier: "th_TH"),
        CurrencyOption(code: "IDR", symbol: "Rp", localeIdentifier: "id_ID"),
        CurrencyOption(code: "MYR", symbol: "RM", localeIdentifier: "ms_MY"),
        CurrencyOption(code: "PHP", symbol: "₱", localeIdentifier: "en_PH"),
        CurrencyOption(code: "VND", symbol: "₫", localeIdentifier: "vi_VN"),
        CurrencyOption(code: "RUB", symbol: "₽", localeIdentifier: "ru_RU"),
        CurrencyOption(code: "NGN", symbol: "₦", localeIdentifier: "en_NG"),
        CurrencyOption(code: "EGP", symbol: "E£", localeIdentifier: "ar_EG"),
        CurrencyOption(code: "PKR", symbol: "₨", localeIdentifier: "en_PK"),
        CurrencyOption(code: "BDT", symbol: "৳", localeIdentifier: "bn_BD"),
        CurrencyOption(code: "LKR", symbol: "Rs", localeIdentifier: "en_LK"),
        CurrencyOption(code: "NPR", symbol: "रू", localeIdentifier: "ne_NP")
    ]

    static let fallback = CurrencyOption(code: "USD", symbol: "$", localeIdentifier: "en_US")

    /// Resolves a stored ISO code without exposing collection lookups throughout the UI.
    static func option(for code: String) -> CurrencyOption {
        supported.first(where: { $0.code == code }) ?? fallback
    }
}
