import SwiftUI

/// The three-page Stats workspace for overview, calendar filtering, and future pro insights.
struct StatsTabView: View {
    @EnvironmentObject private var manager: ExpenseManager
    @State private var selectedPage: StatsPage = .overview
    @State private var categorySort: CategorySort = .highestFirst
    @State private var timeframe: ExpenseTimeframe = .today
    @State private var customStartDate = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
    @State private var customEndDate = Date.now
    @State private var isShowingProMessage = false

    private let analytics: any ExpenseAnalyticsService = LocalExpenseAnalyticsEngine()

    private var lifetimeSummary: ExpenseSummary {
        analytics.calculateSummary(from: manager.transactions)
    }

    private var periodSummary: ExpenseSummary {
        analytics.calculateSummary(
            for: timeframe,
            customStartDate: customStartDate,
            customEndDate: customEndDate,
            from: manager.transactions
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                ScreenTitleView("Stats", subtitle: "Understand where your money goes")

                StatsLineSwitcher(selection: $selectedPage)

                switch selectedPage {
                case .overview:
                    overviewContent
                        .transition(.opacity)
                case .calendar:
                    calendarContent
                        .transition(.opacity)
                case .insights:
                    proInsightsContent
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, AppTheme.pagePadding)
            .padding(.top, 18)
            .padding(.bottom, AppTheme.floatingBarClearance)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background)
        .alert("Insights is a Pro feature", isPresented: $isShowingProMessage) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("A future update will add forecasts, patterns, and personalized spending guidance.")
        }
    }

    private var overviewContent: some View {
        Group {
            VStack(alignment: .leading, spacing: 13) {
                DashboardSectionHeader("Overview", subtitle: "Lifetime spending at a glance")

                StatCardView(
                    title: "Total spent",
                    value: manager.formattedCurrency(lifetimeSummary.totalSpent),
                    symbol: "creditcard.fill",
                    detail: "All time"
                )

                AdaptivePairView {
                    StatCardView(
                        title: "Top spent category",
                        value: lifetimeSummary.topCategory?.category.name ?? "—",
                        symbol: lifetimeSummary.topCategory?.category.symbol ?? "arrow.up",
                        detail: lifetimeSummary.topCategory.map { manager.formattedCurrency($0.totalSpent) } ?? "No data"
                    )
                } trailing: {
                    StatCardView(
                        title: "Least spent category",
                        value: lifetimeSummary.leastCategory?.category.name ?? "—",
                        symbol: lifetimeSummary.leastCategory?.category.symbol ?? "arrow.down",
                        detail: lifetimeSummary.leastCategory.map { manager.formattedCurrency($0.totalSpent) } ?? "No data"
                    )
                }
            }

            categorySection(
                title: "Top 3 categories",
                subtitle: "Highest lifetime spending",
                performances: Array(lifetimeSummary.categoriesBySpending.prefix(3)),
                showsRank: true
            )

            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .center, spacing: 12) {
                    DashboardSectionHeader("Category-wise spending", subtitle: "All categories by total spent")
                    Spacer(minLength: 8)
                    Button {
                        withAnimation(.snappy(duration: 0.22)) {
                            categorySort.toggle()
                        }
                    } label: {
                        Label(categorySort.buttonTitle, systemImage: "arrow.up.arrow.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 11)
                            .frame(minHeight: 38)
                            .background(AppTheme.subtleFill, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Sort \(categorySort.accessibilityDescription)")
                }

                let categories = categorySort.apply(to: lifetimeSummary.categoriesBySpending)
                if categories.isEmpty {
                    EmptyStateView(
                        symbol: "chart.bar.xaxis",
                        title: "No spending yet",
                        message: "Category analytics appear after you add an expense."
                    )
                } else {
                    ForEach(categories) { performance in
                        CategoryPerformanceRowView(
                            performance: performance,
                            amountText: manager.formattedCurrency(performance.totalSpent)
                        )
                    }
                }
            }

            historicalPeaksSection
        }
    }

    private var calendarContent: some View {
        Group {
            VStack(alignment: .leading, spacing: 13) {
                DashboardSectionHeader("Explore a period", subtitle: "Compare a day, week, month, YTD, or custom range")

                ExpensePeriodSwitcher(selection: $timeframe)

                if timeframe == .custom {
                    CustomExpenseDateRangeView(
                        startDate: $customStartDate,
                        endDate: $customEndDate
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }

            AdaptivePairView {
                StatCardView(
                    title: "Total spending",
                    value: manager.formattedCurrency(periodSummary.totalSpent),
                    symbol: "creditcard.fill",
                    detail: timeframe.rawValue
                )
            } trailing: {
                StatCardView(
                    title: "Spend count",
                    value: periodSummary.expenseCount.formatted(),
                    symbol: "number",
                    detail: timeframe.rawValue
                )
            }

            AdaptivePairView {
                StatCardView(
                    title: "Top category",
                    value: periodSummary.topCategory?.category.name ?? "—",
                    symbol: periodSummary.topCategory?.category.symbol ?? "arrow.up",
                    detail: periodSummary.topCategory.map { manager.formattedCurrency($0.totalSpent) } ?? "No data"
                )
            } trailing: {
                StatCardView(
                    title: "Least category",
                    value: periodSummary.leastCategory?.category.name ?? "—",
                    symbol: periodSummary.leastCategory?.category.symbol ?? "arrow.down",
                    detail: periodSummary.leastCategory.map { manager.formattedCurrency($0.totalSpent) } ?? "No data"
                )
            }

            categorySection(
                title: "Top categories",
                subtitle: "Spending in \(timeframe.rawValue.lowercased())",
                performances: periodSummary.categoriesBySpending,
                showsRank: true
            )
        }
    }

    private var proInsightsContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            DashboardSectionHeader("Insights", subtitle: "Personalized intelligence is coming with Pro")

            VStack(alignment: .leading, spacing: 22) {
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 52, height: 52)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Unlock smarter spending insights")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Discover patterns, forecasts, unusual spending, and personalized ways to stay on track.")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    isShowingProMessage = true
                } label: {
                    Text("Get Pro")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white, in: Capsule())
                }
            }
            .padding(22)
            .background(
                LinearGradient(
                    colors: [Color.black, Color(red: 0.16, green: 0.16, blue: 0.19)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
            .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 9)
        }
    }

    /// Builds a ranked or unranked category performance section from an analytics snapshot.
    @ViewBuilder
    private func categorySection(
        title: String,
        subtitle: String,
        performances: [CategoryPerformance],
        showsRank: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            DashboardSectionHeader(title, subtitle: subtitle)

            if performances.isEmpty {
                EmptyStateView(
                    symbol: "chart.bar.xaxis",
                    title: "No performance yet",
                    message: "There are no expenses in this period."
                )
            } else {
                ForEach(Array(performances.enumerated()), id: \.element.id) { index, performance in
                    CategoryPerformanceRowView(
                        performance: performance,
                        amountText: manager.formattedCurrency(performance.totalSpent),
                        rank: showsRank ? index + 1 : nil
                    )
                }
            }
        }
    }

    /// Presents all-time peak periods as neutral cards because they are comparative, not daily totals.
    private var historicalPeaksSection: some View {
        let records: [(String, String, SpendPeriodRecord?)] = [
            ("Top day by spend", "calendar.day.timeline.left", analytics.calculatePeakDay(from: manager.transactions)),
            ("Top week by spend", "calendar.badge.clock", analytics.calculatePeakWeek(from: manager.transactions)),
            ("Top spent month", "calendar", analytics.calculatePeakMonth(from: manager.transactions)),
            ("Top spent quarter", "calendar.badge.plus", analytics.calculatePeakQuarter(from: manager.transactions))
        ]

        return VStack(alignment: .leading, spacing: 13) {
            DashboardSectionHeader("Peak periods", subtitle: "Your highest recorded spending windows")

            if manager.transactions.isEmpty {
                EmptyStateView(
                    symbol: "trophy",
                    title: "No peak periods yet",
                    message: "Peak day, week, month, and quarter appear after the first expense."
                )
            } else {
                ForEach(Array(records.enumerated()), id: \.offset) { _, item in
                    if let record = item.2 {
                        PeakSpendCardView(
                            title: item.0,
                            symbol: item.1,
                            record: record,
                            amountText: manager.formattedCurrency(record.totalSpent)
                        )
                    }
                }
            }
        }
    }
}

/// The three text-and-underline pages inside Stats.
private enum StatsPage: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case calendar = "Calendar"
    case insights = "Insights"

    var id: Self { self }
}

/// The sort direction applied to the lifetime category breakdown.
private enum CategorySort {
    case highestFirst
    case lowestFirst

    var buttonTitle: String { self == .highestFirst ? "Highest" : "Lowest" }
    var accessibilityDescription: String { self == .highestFirst ? "least spending first" : "highest spending first" }

    mutating func toggle() {
        self = self == .highestFirst ? .lowestFirst : .highestFirst
    }

    /// Reverses the already spending-ranked analytics output without recalculating it.
    func apply(to categories: [CategoryPerformance]) -> [CategoryPerformance] {
        self == .highestFirst ? categories : Array(categories.reversed())
    }
}

/// A three-item text-and-underline switcher matching the supplied line-tab reference.
private struct StatsLineSwitcher: View {
    @Binding var selection: StatsPage
    @Namespace private var underlineNamespace

    var body: some View {
        HStack(alignment: .bottom, spacing: 28) {
            ForEach(StatsPage.allCases) { page in
                Button {
                    withAnimation(.snappy(duration: 0.22)) {
                        selection = page
                    }
                } label: {
                    VStack(spacing: 11) {
                        Text(page.rawValue)
                            .font(.subheadline.weight(selection == page ? .semibold : .regular))
                            .foregroundStyle(selection == page ? .primary : .secondary)
                        ZStack {
                            Color.clear.frame(height: 3)
                            if selection == page {
                                Capsule()
                                    .fill(Color.black)
                                    .frame(height: 3)
                                    .matchedGeometryEffect(id: "stats-underline", in: underlineNamespace)
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
            Rectangle().fill(AppTheme.border).frame(height: 1).zIndex(-1)
        }
    }
}

/// A compact five-scope control for calendar-based expense analytics.
private struct ExpensePeriodSwitcher: View {
    @Binding var selection: ExpenseTimeframe

    var body: some View {
        HStack(spacing: 3) {
            ForEach(ExpenseTimeframe.calendarOptions) { option in
                Button {
                    withAnimation(.snappy(duration: 0.22)) {
                        selection = option
                    }
                } label: {
                    Text(option.compactTitle)
                        .font(.caption2.weight(selection == option ? .bold : .medium))
                        .foregroundStyle(selection == option ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background {
                            if selection == option {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.08), radius: 7, x: 0, y: 3)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == option ? .isSelected : [])
            }
        }
        .padding(5)
        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// An inclusive custom calendar range shown only when the custom scope is active.
private struct CustomExpenseDateRangeView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("From")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                DatePicker("From", selection: $startDate, in: ...endDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "arrow.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)

            VStack(alignment: .leading, spacing: 6) {
                Text("To")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                DatePicker("To", selection: $endDate, in: startDate...Date.now, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .cardSurface(radius: AppTheme.compactRadius)
    }
}

#Preview("Stats — Populated") {
    StatsTabView()
        .environmentObject(ExpenseManager.previewPopulated)
        .preferredColorScheme(.light)
}

#Preview("Stats — Empty") {
    StatsTabView()
        .environmentObject(ExpenseManager(storage: nil))
        .preferredColorScheme(.light)
}
