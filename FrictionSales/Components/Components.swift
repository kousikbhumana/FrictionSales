import SwiftUI

extension Font {
    static func poppins(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold: name = "Poppins-Bold"
        case .semibold: name = "Poppins-SemiBold"
        case .medium: name = "Poppins-Medium"
        default: name = "Poppins-Regular"
        }
        let size: CGFloat
        switch style {
        case .largeTitle: size = 34
        case .title: size = 28
        case .title2: size = 22
        case .title3: size = 20
        case .headline: size = 17
        case .body: size = 17
        case .callout: size = 16
        case .subheadline: size = 15
        case .footnote: size = 13
        case .caption: size = 12
        case .caption2: size = 11
        default: size = 16
        }
        return .custom(name, size: size, relativeTo: style)
    }

    static func poppins(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold: name = "Poppins-Bold"
        case .semibold: name = "Poppins-SemiBold"
        case .medium: name = "Poppins-Medium"
        default: name = "Poppins-Regular"
        }
        return .custom(name, size: size)
    }
}

extension ExpenseCategory {
    var displayColor: Color {
        let colors: [Color] = [.blue, .purple, .orange, .pink, .indigo, .teal, .cyan, .green, .mint, .brown, .red, .yellow]
        let index = abs(id.hashValue) % colors.count
        return colors[index]
    }
}


/// Shared visual tokens for the premium, neutral expense interface.
enum AppTheme {
    static let pagePadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 24
    static let cardRadius: CGFloat = 14
    static let compactRadius: CGFloat = 11
    static let floatingBarClearance: CGFloat = 92

    static let background = Color(red: 0.972, green: 0.965, blue: 0.941)
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

    /// Creates a title.
    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.poppins(.title, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A consistent heading and supporting label for dashboard sections.
struct DashboardSectionHeader: View {
    let title: String

    /// Creates a section heading.
    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.poppins(.headline, weight: .bold))
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
            .foregroundStyle(selected ? Color.white : category.displayColor)
            .frame(width: size, height: size)
            .background(
                selected ? category.displayColor : category.displayColor.opacity(0.15),
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
                    .font(.poppins(.headline, weight: .bold))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(transaction.category.name)
                    .font(.poppins(.subheadline))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(transaction.date, format: .dateTime.day().month(.abbreviated).hour().minute())
                    .font(.poppins(.caption))
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.poppins(size: 12, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .cardSurface()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Shows expense details")
    }
}

/// A modern card emphasizing total spend for the selected date.
struct DailyExpenseTotalCard: View {
    let amountText: String
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Total spent", systemImage: "arrow.down.right")
                .font(.poppins(.subheadline, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(amountText)
                .font(.poppins(.largeTitle, weight: .bold))
                .foregroundStyle(.black)
                .minimumScaleFactor(0.62)
                .lineLimit(1)

            Text(date, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.poppins(.caption))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
            
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.12),
                            Color.blue.opacity(0.06),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 9)
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
                    .font(.poppins(size: 13, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .background(AppTheme.subtleFill, in: Circle())

                Spacer(minLength: 4)

                Text(detail)
                    .font(.poppins(.caption2, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.poppins(.title3, weight: .bold))
                    .foregroundStyle(.black)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.62)
                    .lineLimit(1)
                Text(title)
                    .font(.poppins(.caption))
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
                        .font(.poppins(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Color.black, in: Circle())
                        .offset(x: 16, y: -16)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(performance.category.name)
                    .font(.poppins(.subheadline, weight: .semibold))
                Text("\(performance.expenseCount) \(performance.expenseCount == 1 ? "spend" : "spends")")
                    .font(.poppins(.caption))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(amountText)
                .font(.poppins(.subheadline, weight: .bold))
                .foregroundStyle(.black)
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
                .font(.poppins(size: 15, weight: .semibold))
                .frame(width: 42, height: 42)
                .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.poppins(.subheadline, weight: .semibold))
                Text(record.periodLabel)
                    .font(.poppins(.caption))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(amountText)
                    .font(.poppins(.subheadline, weight: .bold))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                Text("\(record.expenseCount) \(record.expenseCount == 1 ? "spend" : "spends")")
                    .font(.poppins(.caption2))
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
                    .font(.poppins(.title2, weight: .bold))
                Text(count == 1 ? "Expense" : "Expenses")
                    .font(.poppins(.caption))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(AppTheme.border)
                .frame(width: 1, height: 54)

            VStack(alignment: .leading, spacing: 5) {
                Text(amountText)
                    .font(.poppins(.title2, weight: .bold))
                    .foregroundStyle(.black)
                    .minimumScaleFactor(0.62)
                    .lineLimit(1)
                Text(amountTitle)
                    .font(.poppins(.caption))
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
                .font(.poppins(size: 21, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 50, height: 50)
                .background(AppTheme.subtleFill, in: Circle())

            VStack(spacing: 5) {
                Text(title)
                    .font(.poppins(.headline))
                Text(message)
                    .font(.poppins(.subheadline))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.poppins(.subheadline, weight: .semibold))
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
                .font(.poppins(.title2, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.poppins(size: 13, weight: .bold))
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
