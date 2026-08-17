import SwiftUI

/// Shared visual tokens for the premium, neutral expense interface.
enum AppTheme {
    static let pagePadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 24
    static let cardRadius: CGFloat = 22
    static let compactRadius: CGFloat = 17
    static let floatingBarClearance: CGFloat = 92

    static let background = Color(red: 0.965, green: 0.965, blue: 0.985)
    static let elevatedSurface = Color.white
    static let subtleFill = Color.black.opacity(0.055)
    static let border = Color.black.opacity(0.055)
    static let expenseRed = Color(red: 0.83, green: 0.17, blue: 0.22)
    static let positiveGreen = Color(red: 0.12, green: 0.55, blue: 0.31)
}

/// Applies the app's soft bordered white card surface and restrained elevation.
private struct CardSurfaceModifier: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.065), radius: 16, x: 0, y: 7)
    }
}

extension View {
    /// Wraps content in the app's reusable light-mode card treatment.
    func cardSurface(radius: CGFloat = AppTheme.cardRadius) -> some View {
        modifier(CardSurfaceModifier(radius: radius))
    }
}

/// Keeps paired metrics horizontal normally and stacks them for accessibility text sizes.
struct AdaptivePairView<Leading: View, Trailing: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let leading: Leading
    private let trailing: Trailing

    /// Creates two pieces of content that adapt between a row and a vertical stack.
    init(@ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                leading
                trailing
            }
        } else {
            HStack(alignment: .top, spacing: 12) {
                leading
                trailing
            }
        }
    }
}

/// A compact, left-aligned screen title matching the supplied dashboard references.
struct ScreenTitleView: View {
    let title: String
    let subtitle: String?

    /// Creates a title with optional supporting context.
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A consistent heading and supporting label for dashboard sections.
struct DashboardSectionHeader: View {
    let title: String
    let subtitle: String?

    /// Creates a section heading with optional explanatory text.
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.title3.weight(.bold))
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A category symbol in the rounded-square treatment shared across the app.
struct CategoryIconView: View {
    let category: ExpenseCategory
    var size: CGFloat = 46
    var selected = false

    var body: some View {
        Image(systemName: category.symbol)
            .font(.system(size: size * 0.32, weight: .semibold))
            .foregroundStyle(selected ? Color.white : Color.primary)
            .frame(width: size, height: size)
            .background(
                selected ? Color.black : AppTheme.subtleFill,
                in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

/// A compact transaction row that opens the full expense-detail bottom sheet.
struct ExpenseRowView: View {
    let transaction: ExpenseTransaction
    let amountText: String

    var body: some View {
        HStack(spacing: 15) {
            CategoryIconView(category: transaction.category, size: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text(amountText)
                    .font(.headline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(transaction.category.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(transaction.date, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .cardSurface()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Shows expense details")
    }
}

/// A red layered-gradient card emphasizing total spend for the selected date.
struct DailyExpenseTotalCard: View {
    let amountText: String
    let date: Date

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.99, green: 0.89, blue: 0.90),
                            Color(red: 0.98, green: 0.95, blue: 0.96),
                            Color(red: 0.96, green: 0.80, blue: 0.83)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(AppTheme.expenseRed.opacity(0.24))
                .frame(width: 150, height: 150)
                .blur(radius: 28)
                .offset(x: 145, y: -70)

            Circle()
                .fill(Color.pink.opacity(0.20))
                .frame(width: 130, height: 130)
                .blur(radius: 28)
                .offset(x: -150, y: 78)

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 7) {
                    Label("Total spent", systemImage: "arrow.down.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.expenseRed)

                    Text(amountText)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .minimumScaleFactor(0.62)
                        .lineLimit(1)

                    Text(date, format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "creditcard.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(AppTheme.expenseRed)
                    .frame(width: 52, height: 52)
                    .background(Color.white.opacity(0.68), in: Circle())
            }
            .padding(22)
        }
        .frame(minHeight: 146)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        }
        .shadow(color: AppTheme.expenseRed.opacity(0.12), radius: 18, x: 0, y: 9)
        .accessibilityElement(children: .combine)
    }
}

/// A compact dashboard card for one high-priority spending metric.
struct StatCardView: View {
    let title: String
    let value: String
    let symbol: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .background(AppTheme.subtleFill, in: Circle())

                Spacer(minLength: 4)

                Text(detail)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.title3.weight(.bold))
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.62)
                    .lineLimit(1)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

/// A ranked or unranked category row used by Stats spending breakdowns.
struct CategoryPerformanceRowView: View {
    let performance: CategoryPerformance
    let amountText: String
    var rank: Int?

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                CategoryIconView(category: performance.category, size: 42)
                if let rank {
                    Text("\(rank)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Color.black, in: Circle())
                        .offset(x: 16, y: -16)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(performance.category.name)
                    .font(.subheadline.weight(.semibold))
                Text("\(performance.expenseCount) \(performance.expenseCount == 1 ? "spend" : "spends")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(amountText)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .padding(15)
        .cardSurface(radius: AppTheme.compactRadius)
        .accessibilityElement(children: .combine)
    }
}

/// Displays one historical spending peak and its full calendar period.
struct PeakSpendCardView: View {
    let title: String
    let symbol: String
    let record: SpendPeriodRecord
    let amountText: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 42, height: 42)
                .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(record.periodLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(amountText)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                Text("\(record.expenseCount) \(record.expenseCount == 1 ? "spend" : "spends")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .cardSurface(radius: AppTheme.compactRadius)
        .accessibilityElement(children: .combine)
    }
}

/// A reusable two-column summary card for category history and detail sheets.
struct MetricPairCardView: View {
    let count: Int
    let amountText: String
    var amountTitle = "Total spent"

    var body: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text(count.formatted())
                    .font(.title2.weight(.bold))
                Text(count == 1 ? "Expense" : "Expenses")
                    .font(.caption)
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
                Text(amountTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

/// A restrained placeholder for a data-driven section with no current content.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 21, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 50, height: 50)
                .background(AppTheme.subtleFill, in: Circle())

            VStack(spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 110, minHeight: 44)
                    .background(Color.black, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 22)
        .padding(.vertical, 28)
        .cardSurface()
    }
}

/// A standard bottom-sheet heading with an accessible circular close control.
struct SheetHeaderView: View {
    let title: String
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.title2.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.subtleFill, in: Circle())
            }
            .accessibilityLabel("Close")
        }
    }
}

#Preview("Expense Components") {
    let manager = ExpenseManager.previewPopulated
    ScrollView {
        VStack(spacing: 18) {
            DailyExpenseTotalCard(amountText: "$145", date: .now)
            if let transaction = manager.transactions.first {
                ExpenseRowView(
                    transaction: transaction,
                    amountText: manager.formattedCurrency(transaction.amount)
                )
            }
            MetricPairCardView(count: 8, amountText: "$1,218")
        }
        .padding(20)
    }
    .background(AppTheme.background)
    .preferredColorScheme(.light)
}
