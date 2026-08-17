import Foundation

/// Defines deterministic expense calculations independently of SwiftUI rendering.
protocol ExpenseAnalyticsService {
    func calculateSummary(from transactions: [ExpenseTransaction]) -> ExpenseSummary
    func calculateSummary(
        for timeframe: ExpenseTimeframe,
        customStartDate: Date,
        customEndDate: Date,
        from transactions: [ExpenseTransaction]
    ) -> ExpenseSummary
    func filterTransactions(
        for timeframe: ExpenseTimeframe,
        customStartDate: Date,
        customEndDate: Date,
        from transactions: [ExpenseTransaction]
    ) -> [ExpenseTransaction]
    func searchTransactions(matching query: String, in transactions: [ExpenseTransaction]) -> [ExpenseTransaction]
    func calculateCategoryHistory(from transactions: [ExpenseTransaction]) -> [CategoryHistorySummary]
    func calculatePeakDay(from transactions: [ExpenseTransaction]) -> SpendPeriodRecord?
    func calculatePeakWeek(from transactions: [ExpenseTransaction]) -> SpendPeriodRecord?
    func calculatePeakMonth(from transactions: [ExpenseTransaction]) -> SpendPeriodRecord?
    func calculatePeakQuarter(from transactions: [ExpenseTransaction]) -> SpendPeriodRecord?
}

/// Performs local expense analytics with linear grouping passes and deterministic tie-breaking.
struct LocalExpenseAnalyticsEngine: ExpenseAnalyticsService {
    private let calendar: Calendar
    private let referenceDate: Date?

    /// Creates an engine with injectable calendar and clock values for deterministic testing.
    init(calendar: Calendar = .current, referenceDate: Date? = nil) {
        self.calendar = calendar
        self.referenceDate = referenceDate
    }

    /// Groups transactions once by category and returns a spending-ranked snapshot.
    func calculateSummary(from transactions: [ExpenseTransaction]) -> ExpenseSummary {
        let groupedTransactions = Dictionary(grouping: transactions, by: { $0.category.id })
        let categories = groupedTransactions.compactMap {
            (categoryID: UUID, categoryTransactions: [ExpenseTransaction]) -> CategoryPerformance? in
            guard let category = categoryTransactions.first?.category else { return nil }

            return CategoryPerformance(
                id: categoryID,
                category: category,
                expenseCount: categoryTransactions.count,
                totalSpent: categoryTransactions.reduce(0) { $0 + $1.amount }
            )
        }
        .sorted(by: categorySpendingSort)

        return ExpenseSummary(
            totalSpent: transactions.reduce(0) { $0 + $1.amount },
            expenseCount: transactions.count,
            categoriesBySpending: categories
        )
    }

    /// Filters a period once before calculating its category and total metrics.
    func calculateSummary(
        for timeframe: ExpenseTimeframe,
        customStartDate: Date,
        customEndDate: Date,
        from transactions: [ExpenseTransaction]
    ) -> ExpenseSummary {
        calculateSummary(
            from: filterTransactions(
                for: timeframe,
                customStartDate: customStartDate,
                customEndDate: customEndDate,
                from: transactions
            )
        )
    }

    /// Returns transactions in the selected calendar scope, with custom endpoints treated as inclusive days.
    func filterTransactions(
        for timeframe: ExpenseTimeframe,
        customStartDate: Date,
        customEndDate: Date,
        from transactions: [ExpenseTransaction]
    ) -> [ExpenseTransaction] {
        let now = referenceDate ?? Date.now

        return transactions.filter { transaction in
            switch timeframe {
            case .today:
                return calendar.isDate(transaction.date, inSameDayAs: now)
            case .thisWeek:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .weekOfYear)
                    && calendar.component(.yearForWeekOfYear, from: transaction.date)
                    == calendar.component(.yearForWeekOfYear, from: now)
            case .thisMonth:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
                    && calendar.component(.year, from: transaction.date) == calendar.component(.year, from: now)
            case .yearToDate:
                guard let yearStart = calendar.dateInterval(of: .year, for: now)?.start else { return false }
                return transaction.date >= yearStart && transaction.date <= now
            case .custom:
                let earlierDate = min(customStartDate, customEndDate)
                let laterDate = max(customStartDate, customEndDate)
                let lowerBound = calendar.startOfDay(for: earlierDate)
                let upperBound = calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: calendar.startOfDay(for: laterDate)
                ) ?? laterDate
                return transaction.date >= lowerBound && transaction.date < upperBound
            case .allTime:
                return true
            }
        }
        .sorted { $0.date > $1.date }
    }

    /// Searches category names and notes after trimming and case-folding user input.
    func searchTransactions(matching query: String, in transactions: [ExpenseTransaction]) -> [ExpenseTransaction] {
        let normalizedQuery = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: calendar.locale)

        guard !normalizedQuery.isEmpty else { return transactions.sorted { $0.date > $1.date } }

        return transactions.filter { transaction in
            let categoryName = transaction.category.name.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: calendar.locale
            )
            let note = transaction.note.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: calendar.locale
            )
            return categoryName.contains(normalizedQuery) || note.contains(normalizedQuery)
        }
        .sorted { $0.date > $1.date }
    }

    /// Groups category history by calendar month and marks highest spending red and least spending green.
    func calculateCategoryHistory(from transactions: [ExpenseTransaction]) -> [CategoryHistorySummary] {
        Dictionary(grouping: transactions, by: { $0.category.id })
            .compactMap { categoryID, categoryTransactions -> CategoryHistorySummary? in
                guard let category = categoryTransactions.first?.category else { return nil }

                let groupedMonths = Dictionary(grouping: categoryTransactions) { transaction in
                    calendar.dateInterval(of: .month, for: transaction.date)?.start
                        ?? calendar.startOfDay(for: transaction.date)
                }
                let monthTotals = groupedMonths.map { monthStart, monthTransactions in
                    (
                        monthStart: monthStart,
                        count: monthTransactions.count,
                        total: monthTransactions.reduce(0) { $0 + $1.amount }
                    )
                }
                let minimum = monthTotals.map(\.total).min()
                let maximum = monthTotals.map(\.total).max()
                let hasDistinctExtremes = minimum != maximum
                let monthlySpending = monthTotals.map { month in
                    let position: MonthSpendingPosition
                    if !hasDistinctExtremes {
                        position = .tied
                    } else if month.total == maximum {
                        position = .highest
                    } else if month.total == minimum {
                        position = .least
                    } else {
                        position = .standard
                    }

                    return MonthlyCategorySpending(
                        monthStart: month.monthStart,
                        expenseCount: month.count,
                        totalSpent: month.total,
                        position: position
                    )
                }
                .sorted { $0.monthStart > $1.monthStart }

                return CategoryHistorySummary(
                    id: categoryID,
                    category: category,
                    expenseCount: categoryTransactions.count,
                    totalSpent: categoryTransactions.reduce(0) { $0 + $1.amount },
                    monthlySpending: monthlySpending
                )
            }
            .sorted {
                if $0.totalSpent == $1.totalSpent {
                    return $0.category.name.localizedStandardCompare($1.category.name) == .orderedAscending
                }
                return $0.totalSpent > $1.totalSpent
            }
    }

    /// Groups expenses by calendar day and selects the highest-spending day.
    func calculatePeakDay(from transactions: [ExpenseTransaction]) -> SpendPeriodRecord? {
        let groups = Dictionary(grouping: transactions) { calendar.startOfDay(for: $0.date) }
        return peakRecord(in: groups, date: { $0 }) { date in
            date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year())
        }
    }

    /// Groups expenses by week-based year and labels the full week date range.
    func calculatePeakWeek(from transactions: [ExpenseTransaction]) -> SpendPeriodRecord? {
        let groups = Dictionary(grouping: transactions) { transaction in
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: transaction.date)
            let startDate = calendar.dateInterval(of: .weekOfYear, for: transaction.date)?.start
                ?? calendar.startOfDay(for: transaction.date)
            return WeekKey(
                year: components.yearForWeekOfYear ?? 0,
                week: components.weekOfYear ?? 0,
                startDate: startDate
            )
        }

        guard let peak = strongestGroup(in: groups, date: { $0.startDate }) else { return nil }
        let endDate = calendar.date(byAdding: .day, value: 6, to: peak.key.startDate) ?? peak.key.startDate
        let label = "\(peak.key.startDate.formatted(.dateTime.day().month(.abbreviated)))–\(endDate.formatted(.dateTime.day().month(.abbreviated).year()))"
        return SpendPeriodRecord(periodLabel: label, totalSpent: peak.total, expenseCount: peak.transactions.count)
    }

    /// Groups expenses by calendar month and selects the highest-spending month.
    func calculatePeakMonth(from transactions: [ExpenseTransaction]) -> SpendPeriodRecord? {
        let groups = Dictionary(grouping: transactions) { transaction in
            calendar.dateInterval(of: .month, for: transaction.date)?.start
                ?? calendar.startOfDay(for: transaction.date)
        }
        return peakRecord(in: groups, date: { $0 }) { date in
            date.formatted(.dateTime.month(.wide).year())
        }
    }

    /// Groups expenses by calendar quarter and labels its month span and year.
    func calculatePeakQuarter(from transactions: [ExpenseTransaction]) -> SpendPeriodRecord? {
        let groups = Dictionary(grouping: transactions) { transaction in
            let year = calendar.component(.year, from: transaction.date)
            let month = calendar.component(.month, from: transaction.date)
            let quarter = ((month - 1) / 3) + 1
            let startMonth = ((quarter - 1) * 3) + 1
            let startDate = calendar.date(from: DateComponents(year: year, month: startMonth, day: 1))
                ?? calendar.startOfDay(for: transaction.date)
            return QuarterKey(year: year, quarter: quarter, startDate: startDate)
        }

        guard let peak = strongestGroup(in: groups, date: { $0.startDate }) else { return nil }
        let finalMonth = calendar.date(byAdding: .month, value: 2, to: peak.key.startDate) ?? peak.key.startDate
        let label = "Q\(peak.key.quarter) · \(peak.key.startDate.formatted(.dateTime.month(.abbreviated)))–\(finalMonth.formatted(.dateTime.month(.abbreviated))) \(peak.key.year)"
        return SpendPeriodRecord(periodLabel: label, totalSpent: peak.total, expenseCount: peak.transactions.count)
    }

    /// Sorts category performance by spending, count, then name for stable results.
    private func categorySpendingSort(_ lhs: CategoryPerformance, _ rhs: CategoryPerformance) -> Bool {
        if lhs.totalSpent == rhs.totalSpent {
            if lhs.expenseCount == rhs.expenseCount {
                return lhs.category.name.localizedStandardCompare(rhs.category.name) == .orderedAscending
            }
            return lhs.expenseCount > rhs.expenseCount
        }
        return lhs.totalSpent > rhs.totalSpent
    }

    /// Converts date-keyed groups into a display-ready record.
    private func peakRecord(
        in groups: [Date: [ExpenseTransaction]],
        date: (Date) -> Date,
        label: (Date) -> String
    ) -> SpendPeriodRecord? {
        guard let peak = strongestGroup(in: groups, date: date) else { return nil }
        return SpendPeriodRecord(
            periodLabel: label(peak.key),
            totalSpent: peak.total,
            expenseCount: peak.transactions.count
        )
    }

    /// Selects the highest-spending group in one pass, using count and recency to break ties.
    private func strongestGroup<Key: Hashable>(
        in groups: [Key: [ExpenseTransaction]],
        date: (Key) -> Date
    ) -> (key: Key, transactions: [ExpenseTransaction], total: Double)? {
        var strongest: (key: Key, transactions: [ExpenseTransaction], total: Double)?

        for (key, groupedTransactions) in groups {
            let candidate = (
                key: key,
                transactions: groupedTransactions,
                total: groupedTransactions.reduce(0) { $0 + $1.amount }
            )

            guard let current = strongest else {
                strongest = candidate
                continue
            }

            let candidateWins: Bool
            if candidate.total == current.total {
                if candidate.transactions.count == current.transactions.count {
                    candidateWins = date(candidate.key) > date(current.key)
                } else {
                    candidateWins = candidate.transactions.count > current.transactions.count
                }
            } else {
                candidateWins = candidate.total > current.total
            }

            if candidateWins { strongest = candidate }
        }

        return strongest
    }
}

private extension LocalExpenseAnalyticsEngine {
    struct WeekKey: Hashable {
        let year: Int
        let week: Int
        let startDate: Date
    }

    struct QuarterKey: Hashable {
        let year: Int
        let quarter: Int
        let startDate: Date
    }
}
