import SwiftUI

/// The daily expense log with a seven-day strip, total card, and transaction details.
struct TodayTabView: View {
    @EnvironmentObject private var manager: ExpenseManager
    @State private var selectedDate = Date.now
    @State private var selectedTransaction: ExpenseTransaction?

    private var selectedExpenses: [ExpenseTransaction] {
        manager.expenses(on: selectedDate)
    }

    private var selectedTotal: Double {
        selectedExpenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                HStack(alignment: .center, spacing: 14) {
                    ScreenTitleView("Today", subtitle: "Everyday spending, clearly tracked")

                    Text(selectedDate, format: .dateTime.day().month(.abbreviated))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 42)
                        .background(AppTheme.subtleFill, in: Capsule())
                }

                WeekDateStrip(selectedDate: $selectedDate)

                DailyExpenseTotalCard(
                    amountText: manager.formattedCurrency(selectedTotal),
                    date: selectedDate
                )

                VStack(alignment: .leading, spacing: 13) {
                    DashboardSectionHeader(
                        "Expenses",
                        subtitle: "\(selectedExpenses.count) \(selectedExpenses.count == 1 ? "spend" : "spends")"
                    )

                    if selectedExpenses.isEmpty {
                        EmptyStateView(
                            symbol: "tray",
                            title: "No expenses here",
                            message: "Tap the plus in the center of the tab bar to add a spend for this date."
                        )
                    } else {
                        ForEach(selectedExpenses) { transaction in
                            Button {
                                selectedTransaction = transaction
                            } label: {
                                ExpenseRowView(
                                    transaction: transaction,
                                    amountText: manager.formattedCurrency(transaction.amount)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.pagePadding)
            .padding(.top, 18)
            .padding(.bottom, AppTheme.floatingBarClearance)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background)
        .sheet(item: $selectedTransaction) { transaction in
            ExpenseDetailsSheet(transaction: transaction)
                .environmentObject(manager)
        }
    }
}

/// A responsive seven-column calendar strip anchored to the selected date's week.
private struct WeekDateStrip: View {
    @Binding var selectedDate: Date
    private let calendar = Calendar.current

    private var weekDates: [Date] {
        let start = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start
            ?? calendar.startOfDay(for: selectedDate)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(minimum: 32), spacing: 4), count: 7),
            spacing: 8
        ) {
            ForEach(weekDates, id: \.self) { date in
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)

                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        selectedDate = date
                    }
                } label: {
                    VStack(spacing: 7) {
                        Text(date, format: .dateTime.weekday(.abbreviated))
                            .font(.caption2.weight(isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? .primary : .secondary)
                            .minimumScaleFactor(0.75)

                        Text(date, format: .dateTime.day())
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 38, height: 38)
                            .background(isSelected ? AppTheme.subtleFill : Color.clear, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

/// The complete add-or-edit expense form used by the centered plus and detail actions.
struct AddExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var manager: ExpenseManager
    let transaction: ExpenseTransaction?
    @State private var amount: Double?
    @State private var selectedCategoryID: UUID?
    @State private var expenseDate: Date
    @State private var note: String
    @FocusState private var focusedField: Field?

    /// Creates either a blank add form or a prefilled editor for an existing transaction.
    init(transaction: ExpenseTransaction? = nil) {
        self.transaction = transaction
        _amount = State(initialValue: transaction?.amount)
        _selectedCategoryID = State(initialValue: transaction?.category.id)
        _expenseDate = State(initialValue: transaction?.date ?? .now)
        _note = State(initialValue: transaction?.note ?? "")
    }

    private enum Field {
        case amount
        case note
    }

    private var selectedCategory: ExpenseCategory? {
        availableCategories.first(where: { $0.id == selectedCategoryID })
    }

    private var availableCategories: [ExpenseCategory] {
        guard let transaction,
              !manager.categories.contains(where: { $0.id == transaction.category.id }) else {
            return manager.categories
        }
        return [transaction.category] + manager.categories
    }

    private var isEditing: Bool { transaction != nil }
    private var formTitle: String { isEditing ? "Edit Expense" : "Add Expense" }
    private var submitTitle: String { isEditing ? "Save Changes" : "Add Expense" }

    private var canSubmit: Bool {
        guard let amount, let selectedCategory else { return false }
        if let transaction {
            return manager.canUpdateExpense(
                id: transaction.id,
                amount: amount,
                category: selectedCategory,
                date: expenseDate,
                note: note
            )
        }
        return manager.canRecordExpense(
            amount: amount,
            category: selectedCategory,
            date: expenseDate,
            note: note
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SheetHeaderView(title: formTitle) { dismiss() }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount spent")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 9) {
                        Text(manager.selectedCurrency.symbol)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.secondary)

                        TextField(
                            "0.00",
                            value: $amount,
                            format: .number.precision(.fractionLength(0...2))
                        )
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amount)
                        .minimumScaleFactor(0.65)
                    }
                    .padding(.horizontal, 18)
                    .frame(minHeight: 84)
                    .cardSurface()
                }

                VStack(alignment: .leading, spacing: 12) {
                    DashboardSectionHeader("Category", subtitle: "Choose what this spend was for")

                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(availableCategories) { category in
                                let isSelected = selectedCategoryID == category.id
                                Button {
                                    withAnimation(.snappy(duration: 0.2)) {
                                        selectedCategoryID = category.id
                                    }
                                } label: {
                                    VStack(spacing: 7) {
                                        CategoryIconView(category: category, size: 48, selected: isSelected)
                                        Text(category.name)
                                            .font(.caption2.weight(isSelected ? .bold : .medium))
                                            .foregroundStyle(isSelected ? .primary : .secondary)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 64)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(category.name)
                                .accessibilityAddTraits(isSelected ? .isSelected : [])
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .scrollIndicators(.hidden)
                }

                VStack(spacing: 0) {
                    HStack(spacing: 13) {
                        formIcon("calendar")
                        Text("Date")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        DatePicker(
                            "Date",
                            selection: $expenseDate,
                            in: ...Date.now,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                    }
                    .padding(.vertical, 15)

                    Divider().padding(.leading, 42)

                    HStack(spacing: 13) {
                        formIcon("clock")
                        Text("Time")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        DatePicker(
                            "Time",
                            selection: $expenseDate,
                            in: ...Date.now,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                    .padding(.vertical, 15)
                }
                .padding(.horizontal, 16)
                .cardSurface()

                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        Text("Note")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(note.count)/240")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    ZStack(alignment: .topLeading) {
                        if note.isEmpty {
                            Text("What was this expense for?")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }

                        TextEditor(text: $note)
                            .font(.subheadline)
                            .focused($focusedField, equals: .note)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 92)
                            .onChange(of: note) { _, newValue in
                                if newValue.count > 240 {
                                    note = String(newValue.prefix(240))
                                }
                            }
                    }
                    .padding(12)
                    .cardSurface()
                }

                Button(action: submitExpense) {
                    Text(submitTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.black, in: Capsule())
                }
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1 : 0.35)
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .background(AppTheme.background)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(34)
        .presentationBackground(AppTheme.background)
        .onAppear {
            if selectedCategoryID == nil {
                selectedCategoryID = manager.categories.first?.id
            }
        }
    }

    /// Creates the leading SF Symbol shared by the date and time rows.
    private func formIcon(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(width: 28, height: 28)
            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 8))
    }

    /// Creates or updates only a fully validated expense, then dismisses after persistence succeeds.
    private func submitExpense() {
        guard let amount, let selectedCategory, canSubmit else { return }

        let didSave: Bool
        if let transaction {
            didSave = manager.updateExpense(
                id: transaction.id,
                amount: amount,
                category: selectedCategory,
                date: expenseDate,
                note: note
            )
        } else {
            didSave = manager.recordExpense(
                amount: amount,
                category: selectedCategory,
                date: expenseDate,
                note: note
            )
        }

        if didSave {
            dismiss()
        }
    }
}

/// A bottom sheet containing the latest persisted details and actions for one expense.
struct ExpenseDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var manager: ExpenseManager
    let transaction: ExpenseTransaction
    @State private var isPresentingEditor = false
    @State private var isConfirmingDeletion = false

    private var displayedTransaction: ExpenseTransaction {
        manager.transactions.first(where: { $0.id == transaction.id }) ?? transaction
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SheetHeaderView(title: "Expense Details") { dismiss() }

                HStack(spacing: 16) {
                    CategoryIconView(category: displayedTransaction.category, size: 62)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(manager.formattedCurrency(displayedTransaction.amount))
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .minimumScaleFactor(0.62)
                            .lineLimit(1)
                        Text(displayedTransaction.category.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .cardSurface()

                VStack(spacing: 0) {
                    DetailRow(
                        symbol: "calendar",
                        title: "Date",
                        value: displayedTransaction.date.formatted(.dateTime.weekday(.wide).day().month(.wide).year())
                    )
                    Divider().padding(.leading, 46)
                    DetailRow(
                        symbol: "clock",
                        title: "Time",
                        value: displayedTransaction.date.formatted(.dateTime.hour().minute())
                    )
                    Divider().padding(.leading, 46)
                    DetailRow(
                        symbol: "square.grid.2x2",
                        title: "Category",
                        value: displayedTransaction.category.name
                    )
                }
                .padding(.horizontal, 16)
                .cardSurface()

                VStack(alignment: .leading, spacing: 9) {
                    Text("Note")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(displayedTransaction.note.isEmpty ? "No note added" : displayedTransaction.note)
                        .font(.subheadline)
                        .foregroundStyle(displayedTransaction.note.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .cardSurface()
                }

                HStack(spacing: 12) {
                    Button {
                        isPresentingEditor = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.black, in: Capsule())
                    }
                    .accessibilityHint("Opens this expense in the editor")

                    Button {
                        isConfirmingDeletion = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .font(.headline)
                            .foregroundStyle(AppTheme.expenseRed)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppTheme.expenseRed.opacity(0.10), in: Capsule())
                    }
                    .accessibilityHint("Permanently removes this expense")
                }
            }
            .padding(20)
        }
        .background(AppTheme.background)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(34)
        .presentationBackground(AppTheme.background)
        .sheet(isPresented: $isPresentingEditor) {
            AddExpenseSheet(transaction: displayedTransaction)
                .environmentObject(manager)
        }
        .alert("Delete this expense?", isPresented: $isConfirmingDeletion) {
            Button("Delete", role: .destructive, action: deleteExpense)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This transaction will be removed from Today, History, and Stats. This cannot be undone.")
        }
    }

    /// Deletes the selected expense and closes its now-invalid detail presentation.
    private func deleteExpense() {
        if manager.deleteExpense(id: transaction.id) {
            dismiss()
        }
    }
}

/// One icon, label, and value row inside an expense detail surface.
private struct DetailRow: View {
    let symbol: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 30)
            Text(title)
                .font(.subheadline)
            Spacer(minLength: 10)
            Text(value)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 15)
    }
}

#Preview("Today — Populated") {
    TodayTabView()
        .environmentObject(ExpenseManager.previewPopulated)
        .preferredColorScheme(.light)
}

#Preview("Add Expense") {
    AddExpenseSheet()
        .environmentObject(ExpenseManager.previewPopulated)
        .preferredColorScheme(.light)
}

#Preview("Edit Expense") {
    let manager = ExpenseManager.previewPopulated
    if let transaction = manager.transactions.first {
        AddExpenseSheet(transaction: transaction)
            .environmentObject(manager)
            .preferredColorScheme(.light)
    }
}
