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
    
    private var overallTotal: Double {
        manager.transactions.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                ScreenTitleView("History")

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
            .padding(.top, 4)
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
            DashboardSectionHeader("Spends")

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search category or note", text: $searchText)
                    .font(.poppins(.subheadline))
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
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var categoriesContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            DashboardSectionHeader("Category history")

            if categoryHistory.isEmpty {
                EmptyStateView(
                    symbol: "square.grid.2x2",
                    title: "No category history",
                    message: "Category totals and monthly spending appear after the first expense."
                )
            } else {
                ForEach(categoryHistory) { summary in
                    let percentage = overallTotal > 0 ? (summary.totalSpent / overallTotal) : 0
                    Button {
                        selectedCategory = summary
                    } label: {
                        CategoryHistoryCard(
                            summary: summary,
                            percentage: percentage,
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
    case transactions = "Spends"
    case categories = "Categories"

    var id: Self { self }
}

/// A reference-matched line tab with a full-width hairline and animated active underline.
private struct HistoryLineSwitcher: View {
    @Binding var selection: HistoryPage
    @Namespace private var underlineNamespace

    var body: some View {
        HStack(alignment: .bottom, spacing: 28) {
            ForEach(HistoryPage.allCases) { page in
                Button {
                    withAnimation(.snappy(duration: 0.22)) {
                        selection = page
                    }
                } label: {
                    VStack(spacing: 11) {
                        Text(page.rawValue)
                            .font(.poppins(.subheadline, weight: selection == page ? .semibold : .regular))
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

/// A progress bar that changes color based on the percentage of total spend.
private struct CategoryProgressBar: View {
    let percentage: Double // 0.0 to 1.0

    private var barColor: Color {
        if percentage > 0.70 { return .red }
        if percentage >= 0.30 { return .orange }
        return AppTheme.positiveGreen
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                
                Capsule()
                    .fill(barColor)
                    .frame(width: max(0, min(proxy.size.width, proxy.size.width * percentage)))
            }
        }
        .frame(height: 6)
    }
}

/// A category summary card adapted from the former fleet-history card layout.
private struct CategoryHistoryCard: View {
    let summary: CategoryHistorySummary
    let percentage: Double
    let amountText: String

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                CategoryIconView(category: summary.category, size: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.category.name)
                        .font(.poppins(.headline))
                        .lineLimit(1)
                    
                    Text("Total Spent: \(amountText)")
                        .font(.poppins(.caption))
                        .foregroundStyle(.secondary)
                    
                    Text("Total Expenses: \(summary.expenseCount)")
                        .font(.poppins(.caption))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            
            HStack(spacing: 12) {
                CategoryProgressBar(percentage: percentage)
                
                Text("\(Int(percentage * 100))%")
                    .font(.poppins(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .trailing)
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
    
    private var top5Transactions: [ExpenseTransaction] {
        manager.transactions
            .filter { $0.category == summary.category }
            .sorted { $0.amount > $1.amount }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SheetHeaderView(title: summary.category.name) { dismiss() }

                // Top line aligned header card containing the icon and metrics
                HStack(alignment: .top, spacing: 18) {
                    CategoryIconView(category: summary.category, size: 54)
                    
                    HStack(alignment: .top, spacing: 18) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(summary.expenseCount.formatted())
                                .font(.poppins(.title2, weight: .bold))
                            Text(summary.expenseCount == 1 ? "Expense" : "Expenses")
                                .font(.poppins(.caption))
                                .foregroundStyle(.secondary)
                        }
                        
                        Rectangle()
                            .fill(AppTheme.border)
                            .frame(width: 1, height: 44)
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 5) {
                            Text(manager.formattedCurrency(summary.totalSpent))
                                .font(.poppins(.title2, weight: .bold))
                                .foregroundStyle(.black)
                                .minimumScaleFactor(0.62)
                                .lineLimit(1)
                            Text("Lifetime spent")
                                .font(.poppins(.caption))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 2)
                    
                    Spacer()
                }
                .padding(20)
                .cardSurface()
                
                // Top 5 Spends Chart and List
                if !top5Transactions.isEmpty {
                    TopSpendsChartView(transactions: top5Transactions, manager: manager)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Month")
                        Spacer()
                        Text("Monthly spending")
                    }
                    .font(.poppins(.caption, weight: .semibold))
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
        .presentationDetents([.large]) // Use large detent because there's more content now
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(22)
        .presentationBackground(AppTheme.background)
    }
}

/// A chart rendering the top 5 expenses for a category, matched to the gradient style requested.
private struct TopSpendsChartView: View {
    let transactions: [ExpenseTransaction]
    let manager: ExpenseManager
    
    var body: some View {
        let maxAmount = transactions.map(\.amount).max() ?? 1.0
        let safeMax = maxAmount > 0 ? maxAmount : 1.0
        let avgAmount = transactions.isEmpty ? 0 : transactions.map(\.amount).reduce(0, +) / Double(transactions.count)
        let avgHeightRatio = avgAmount / safeMax
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Spends")
                .font(.poppins(.headline))
            
            GeometryReader { proxy in
                ZStack {
                    // Average dashed line
                    if !transactions.isEmpty {
                        let yPos = proxy.size.height * (1.0 - avgHeightRatio)
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: yPos))
                            path.addLine(to: CGPoint(x: proxy.size.width - 30, y: yPos))
                        }
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(Color(.systemGray3))
                        
                        Text("avg")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .position(x: proxy.size.width - 12, y: yPos)
                    }
                    
                    // Gradient Bars
                    HStack(alignment: .bottom, spacing: 12) {
                        ForEach(transactions) { tx in
                            let heightRatio = tx.amount / safeMax
                            let barHeight = max(2, proxy.size.height * heightRatio)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.8), Color.orange, Color.red],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: (proxy.size.width - 48 - 30) / 5)
                                .frame(height: barHeight)
                        }
                        
                        // Fill remaining empty slots up to 5 with faint gray blocks
                        if transactions.count < 5 {
                            ForEach(0..<(5 - transactions.count), id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(.systemGray6))
                                    .frame(width: (proxy.size.width - 48 - 30) / 5)
                                    .frame(height: 16) // Just a tiny placeholder height
                            }
                        }
                        
                        Spacer(minLength: 30) // Space for the avg label
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            }
            .frame(height: 160)
            .padding(.vertical, 8)
            
            // List beneath the chart
            VStack(spacing: 0) {
                ForEach(transactions) { tx in
                    HStack {
                        Text(tx.date, format: .dateTime.day().month(.wide).year())
                            .font(.poppins(.subheadline))
                        Spacer()
                        Text(manager.formattedCurrency(tx.amount))
                            .font(.poppins(.subheadline, weight: .semibold))
                            .foregroundStyle(.black)
                    }
                    .padding(.vertical, 12)
                    
                    if tx.id != transactions.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(20)
        .cardSurface()
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
                        .font(.poppins(.subheadline, weight: .semibold))
                    if let badge {
                        Text(badge)
                            .font(.poppins(.caption2, weight: .bold))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(accent.opacity(0.10), in: Capsule())
                    }
                }
                Text("\(month.expenseCount) \(month.expenseCount == 1 ? "expense" : "expenses")")
                    .font(.poppins(.caption))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(amountText)
                .font(.poppins(.subheadline, weight: .bold))
                .foregroundStyle(month.position == .highest || month.position == .least ? accent : .black)
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
