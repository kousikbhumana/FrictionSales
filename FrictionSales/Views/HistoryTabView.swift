import SwiftUI

/// The transaction and category archive, with tap-through lifetime category details.
struct HistoryTabView: View {
    @EnvironmentObject private var manager: ExpenseManager
    @State private var selectedPage: HistoryPage = .transactions
    @State private var selectedTransaction: ExpenseTransaction?
    @State private var selectedCategory: CategoryHistorySummary?
    @State private var searchText = ""

    private let analytics: any ExpenseAnalyticsService = LocalExpenseAnalyticsEngine()

    private var searchedTransactions: [ExpenseTransaction] {
        analytics.searchTransactions(matching: searchText, in: manager.transactions)
    }

    private var categoryHistory: [CategoryHistorySummary] {
        analytics.calculateCategoryHistory(from: manager.transactions)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                ScreenTitleView("History", subtitle: "Transactions and category archive")

                HistoryLineSwitcher(selection: $selectedPage)

                if selectedPage == .transactions {
                    transactionsContent
                        .transition(.opacity)
                } else {
                    categoriesContent
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, AppTheme.pagePadding)
            .padding(.top, 18)
            .padding(.bottom, AppTheme.floatingBarClearance)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .background(AppTheme.background)
        .sheet(item: $selectedTransaction) { transaction in
            ExpenseDetailsSheet(transaction: transaction)
                .environmentObject(manager)
        }
        .sheet(item: $selectedCategory) { summary in
            CategoryDetailsSheet(summary: summary)
                .environmentObject(manager)
        }
    }

    private var transactionsContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            DashboardSectionHeader(
                "Transactions",
                subtitle: "\(searchedTransactions.count) \(searchedTransactions.count == 1 ? "record" : "records")"
            )

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search category or note", text: $searchText)
                    .font(.subheadline)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 15)
            .frame(minHeight: 46)
            .cardSurface(radius: AppTheme.compactRadius)

            if searchedTransactions.isEmpty {
                EmptyStateView(
                    symbol: searchText.isEmpty ? "clock.arrow.circlepath" : "magnifyingglass",
                    title: searchText.isEmpty ? "No transaction history" : "No matching expenses",
                    message: searchText.isEmpty
                        ? "Expenses you add will appear here in newest-first order."
                        : "Try another category name or note."
                )
            } else {
                ForEach(searchedTransactions) { transaction in
                    Button {
                        selectedTransaction = transaction
                    } label: {
                        VStack(alignment: .leading, spacing: 9) {
                            ExpenseRowView(
                                transaction: transaction,
                                amountText: manager.formattedCurrency(transaction.amount)
                            )
                            Text(transaction.date, format: .dateTime.day().month(.abbreviated).year())
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 8)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var categoriesContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            DashboardSectionHeader(
                "Category history",
                subtitle: "Lifetime expense count and total spent"
            )

            if categoryHistory.isEmpty {
                EmptyStateView(
                    symbol: "square.grid.2x2",
                    title: "No category history",
                    message: "Category totals and monthly spending appear after the first expense."
                )
            } else {
                ForEach(categoryHistory) { summary in
                    Button {
                        selectedCategory = summary
                    } label: {
                        CategoryHistoryCard(
                            summary: summary,
                            amountText: manager.formattedCurrency(summary.totalSpent)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// The two text-and-underline pages used by History.
private enum HistoryPage: String, CaseIterable, Identifiable {
    case transactions = "Transactions"
    case categories = "Categories"

    var id: Self { self }
}

/// A reference-matched line tab with a full-width hairline and animated active underline.
private struct HistoryLineSwitcher: View {
    @Binding var selection: HistoryPage
    @Namespace private var underlineNamespace

    var body: some View {
        HStack(alignment: .bottom, spacing: 34) {
            ForEach(HistoryPage.allCases) { page in
                Button {
                    withAnimation(.snappy(duration: 0.22)) {
                        selection = page
                    }
                } label: {
                    VStack(spacing: 11) {
                        Text(page.rawValue)
                            .font(.headline.weight(selection == page ? .semibold : .regular))
                            .foregroundStyle(selection == page ? .primary : .secondary)

                        ZStack {
                            Color.clear.frame(height: 3)
                            if selection == page {
                                Capsule()
                                    .fill(Color.black)
                                    .frame(height: 3)
                                    .matchedGeometryEffect(id: "history-underline", in: underlineNamespace)
                            }
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == page ? .isSelected : [])
            }

            Spacer(minLength: 0)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.border)
                .frame(height: 1)
                .zIndex(-1)
        }
    }
}

/// A category summary card adapted from the former fleet-history card layout.
private struct CategoryHistoryCard: View {
    let summary: CategoryHistorySummary
    let amountText: String

    var body: some View {
        VStack(spacing: 17) {
            HStack(spacing: 14) {
                CategoryIconView(category: summary.category, size: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.category.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text("View monthly spending")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.tertiary)
            }

            Divider()

            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(summary.expenseCount.formatted())
                        .font(.title2.weight(.bold))
                    Text("Expenses")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(AppTheme.border)
                    .frame(width: 1, height: 54)

                VStack(alignment: .leading, spacing: 5) {
                    Text(amountText)
                        .font(.title2.weight(.bold))
                        .minimumScaleFactor(0.62)
                        .lineLimit(1)
                    Text("Total spent")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .cardSurface()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Shows monthly category spending")
    }
}

/// The bottom-up monthly spending detail for one category.
private struct CategoryDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var manager: ExpenseManager
    let summary: CategoryHistorySummary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SheetHeaderView(title: summary.category.name) { dismiss() }

                HStack(spacing: 14) {
                    CategoryIconView(category: summary.category, size: 54)
                    MetricPairCardView(
                        count: summary.expenseCount,
                        amountText: manager.formattedCurrency(summary.totalSpent),
                        amountTitle: "Lifetime spent"
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Month")
                        Spacer()
                        Text("Monthly spending")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 3)

                    ForEach(summary.monthlySpending) { month in
                        MonthlySpendingRow(
                            month: month,
                            amountText: manager.formattedCurrency(month.totalSpent)
                        )
                    }
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background)
        .presentationDetents([.fraction(0.72), .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(34)
        .presentationBackground(AppTheme.background)
    }
}

/// One category month with inverted expense semantics for high and low accents.
private struct MonthlySpendingRow: View {
    let month: MonthlyCategorySpending
    let amountText: String

    private var accent: Color {
        switch month.position {
        case .highest: AppTheme.expenseRed
        case .least: AppTheme.positiveGreen
        case .standard, .tied: .secondary
        }
    }

    private var badge: String? {
        switch month.position {
        case .highest: "Top spent"
        case .least: "Least spent"
        case .standard, .tied: nil
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(month.monthStart, format: .dateTime.month(.wide).year())
                        .font(.subheadline.weight(.semibold))
                    if let badge {
                        Text(badge)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(accent.opacity(0.10), in: Capsule())
                    }
                }
                Text("\(month.expenseCount) \(month.expenseCount == 1 ? "expense" : "expenses")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(amountText)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(month.position == .highest || month.position == .least ? accent : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .padding(16)
        .cardSurface(radius: AppTheme.compactRadius)
        .accessibilityElement(children: .combine)
    }
}

#Preview("History — Populated") {
    HistoryTabView()
        .environmentObject(ExpenseManager.previewPopulated)
        .preferredColorScheme(.light)
}

#Preview("History — Empty") {
    HistoryTabView()
        .environmentObject(ExpenseManager(storage: nil))
        .preferredColorScheme(.light)
}
