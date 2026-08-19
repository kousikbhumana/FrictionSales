import SwiftUI

/// Coordinates the four expense workspaces and the centered-add floating navigation pill.
struct ContentView: View {
    @EnvironmentObject private var manager: ExpenseManager
    @State private var selectedTab: AppTab = .today
    @State private var isPresentingNewExpense = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            switch selectedTab {
            case .today:
                TodayTabView()
            case .history:
                HistoryTabView()
            case .stats:
                StatsTabView()
            case .profile:
                ProfileTabView()
            }
        }
        .tint(.black)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FloatingExpenseTabBar(
                selection: $selectedTab,
                addAction: { isPresentingNewExpense = true }
            )
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $isPresentingNewExpense) {
            AddExpenseSheet()
                .environmentObject(manager)
        }
        .preferredColorScheme(.light)
    }
}

/// The four destinations placed around the central add-expense action.
private enum AppTab: Hashable, CaseIterable {
    case today
    case history
    case stats
    case profile

    var symbol: String {
        switch self {
        case .today: "house.fill"
        case .history: "clock.arrow.circlepath"
        case .stats: "chart.bar.fill"
        case .profile: "person.crop.circle.fill"
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .today: "Today"
        case .history: "History"
        case .stats: "Stats"
        case .profile: "Profile"
        }
    }
}

/// A single white capsule with a large black add control centered between four destinations.
private struct FloatingExpenseTabBar: View {
    @Binding var selection: AppTab
    let addAction: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            tabButton(.today)
            tabButton(.history)

            Button(action: addAction) {
                Image(systemName: "plus")
                    .font(.poppins(size: 19, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.black, in: Capsule())
            }
            .frame(maxWidth: 78)
            .accessibilityLabel("Add expense")

            tabButton(.stats)
            tabButton(.profile)
        }
        .padding(6)
        .frame(maxWidth: 350)
        .background(Color.white, in: Capsule())
        .overlay {
            Capsule().stroke(Color.black.opacity(0.05), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 9)
        .frame(maxWidth: .infinity)
    }

    /// Builds a minimum-44-point destination target with a quiet selected state.
    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.22)) {
                selection = tab
            }
        } label: {
            Image(systemName: tab.symbol)
                .font(.poppins(size: 15, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(selection == tab ? Color.black : Color.black.opacity(0.48))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background {
                    if selection == tab {
                        Circle()
                            .fill(Color.black.opacity(0.05))
                            .frame(width: 40, height: 40)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.accessibilityTitle)
        .accessibilityAddTraits(selection == tab ? .isSelected : [])
    }
}

#Preview("Expense Tracker") {
    ContentView()
        .environmentObject(ExpenseManager.previewPopulated)
        .preferredColorScheme(.light)
}
