import SwiftUI

/// The profile workspace for user identity, global currency, and expense categories.
struct ProfileTabView: View {
    @EnvironmentObject private var manager: ExpenseManager
    @State private var draftName = ""
    @State private var isPresentingCurrencyPicker = false
    @State private var isPresentingNewCategory = false
    @State private var pendingCategoryDeletion: ExpenseCategory?

    private var canSaveName: Bool {
        manager.canUpdateProfileName(draftName)
            && draftName.trimmingCharacters(in: .whitespacesAndNewlines) != manager.profileName
    }

    private var profileInitial: String {
        manager.profileName.trimmingCharacters(in: .whitespacesAndNewlines).first.map(String.init) ?? "P"
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                ScreenTitleView("Profile")

                VStack(spacing: 18) {
                    Text(profileInitial.uppercased())
                        .font(.poppins(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(Color.black, in: Circle())

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your name")
                            .font(.poppins(.caption, weight: .semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            TextField("Profile name", text: $draftName)
                                .font(.poppins(.headline))
                                .textInputAutocapitalization(.words)
                                .submitLabel(.done)
                                .onSubmit(saveProfileName)

                            Button("Save", action: saveProfileName)
                                .font(.poppins(.caption, weight: .bold))
                                .foregroundStyle(canSaveName ? Color.white : Color.secondary)
                                .padding(.horizontal, 13)
                                .frame(minHeight: 38)
                                .background(canSaveName ? Color.black : AppTheme.subtleFill, in: Capsule())
                                .disabled(!canSaveName)
                        }
                        .padding(.horizontal, 15)
                        .frame(minHeight: 52)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .cardSurface()

                VStack(alignment: .leading, spacing: 13) {
                    DashboardSectionHeader("App settings")

                    Button {
                        isPresentingCurrencyPicker = true
                    } label: {
                        HStack(spacing: 14) {
                            Text(manager.selectedCurrency.symbol)
                                .font(.poppins(.title3, weight: .bold))
                                .frame(width: 46, height: 46)
                                .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 13))

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Currency")
                                    .font(.poppins(.subheadline, weight: .semibold))
                                Text("\(manager.selectedCurrency.displayName) · \(manager.currencyCode)")
                                    .font(.poppins(.caption))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 8)

                            Image(systemName: "chevron.right")
                                .font(.poppins(size: 12, weight: .bold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .cardSurface(radius: AppTheme.compactRadius)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Choose an app-wide currency")
                }

                VStack(alignment: .leading, spacing: 13) {
                    HStack(alignment: .center, spacing: 12) {
                        DashboardSectionHeader("Categories")
                        Spacer(minLength: 8)
                        Button {
                            isPresentingNewCategory = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.poppins(size: 13, weight: .bold))
                                .frame(width: 42, height: 42)
                                .background(AppTheme.subtleFill, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add category")
                    }

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 96), spacing: 10)],
                        spacing: 10
                    ) {
                        ForEach(manager.categories) { category in
                            CategoryManagementTile(category: category) {
                                pendingCategoryDeletion = category
                            }
                        }
                    }

                    Text("Built-in categories stay available. Removing a custom category never deletes its existing expenses.")
                        .font(.poppins(.caption2))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, AppTheme.pagePadding)
            .padding(.top, 4)
            .padding(.bottom, AppTheme.floatingBarClearance)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .background(AppTheme.background)
        .onAppear { draftName = manager.profileName }
        .sheet(isPresented: $isPresentingCurrencyPicker) {
            CurrencyPickerSheet()
                .environmentObject(manager)
        }
        .sheet(isPresented: $isPresentingNewCategory) {
            AddCategorySheet()
                .environmentObject(manager)
        }
        .confirmationDialog(
            "Remove custom category?",
            isPresented: Binding(
                get: { pendingCategoryDeletion != nil },
                set: { if !$0 { pendingCategoryDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingCategoryDeletion
        ) { category in
            Button("Remove \(category.name)", role: .destructive) {
                manager.deleteCategory(category)
                pendingCategoryDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                pendingCategoryDeletion = nil
            }
        } message: { _ in
            Text("Existing expenses keep their saved category details.")
        }
    }

    /// Saves a valid trimmed name and syncs the field to its canonical stored value.
    private func saveProfileName() {
        if manager.updateProfileName(draftName) {
            draftName = manager.profileName
        }
    }
}

/// A compact category tile with a delete affordance only for user-created entries.
private struct CategoryManagementTile: View {
    let category: ExpenseCategory
    let deleteAction: () -> Void

    var body: some View {
        VStack(spacing: 9) {
            ZStack(alignment: .topTrailing) {
                CategoryIconView(category: category, size: 46)

                if category.isCustom {
                    Button(action: deleteAction) {
                        Image(systemName: "minus")
                            .font(.poppins(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(AppTheme.expenseRed, in: Circle())
                    }
                    .offset(x: 7, y: -7)
                    .accessibilityLabel("Remove \(category.name)")
                }
            }

            Text(category.name)
                .font(.poppins(.caption, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .cardSurface(radius: AppTheme.compactRadius)
    }
}

/// A searchable bottom sheet containing the supported global currencies.
private struct CurrencyPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var manager: ExpenseManager
    @State private var searchText = ""

    private var filteredCurrencies: [CurrencyOption] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return CurrencyOption.supported }
        return CurrencyOption.supported.filter {
            $0.code.localizedCaseInsensitiveContains(query)
                || $0.displayName.localizedCaseInsensitiveContains(query)
                || $0.symbol.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                SheetHeaderView(title: "Choose Currency") { dismiss() }

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search name, code, or symbol", text: $searchText)
                        .font(.poppins(.subheadline))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 15)
                .frame(minHeight: 46)
                .cardSurface(radius: AppTheme.compactRadius)

                ForEach(filteredCurrencies) { currency in
                    Button {
                        manager.updateCurrency(currency)
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Text(currency.symbol)
                                .font(.poppins(.headline))
                                .frame(width: 44, height: 44)
                                .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(currency.displayName)
                                    .font(.poppins(.subheadline, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text(currency.code)
                                    .font(.poppins(.caption))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if manager.currencyCode == currency.code {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.black)
                            }
                        }
                        .padding(14)
                        .cardSurface(radius: AppTheme.compactRadius)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
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
    }
}

/// A validated form for adding a named category backed by an approved SF Symbol.
private struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var manager: ExpenseManager
    @State private var categoryName = ""
    @State private var selectedSymbol = "fork.knife"
    @FocusState private var isNameFocused: Bool

    private var canSubmit: Bool {
        manager.canAddCategory(name: categoryName, symbol: selectedSymbol)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SheetHeaderView(title: "New Category") { dismiss() }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Category name")
                        .font(.poppins(.caption, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField("e.g. Pets", text: $categoryName)
                        .font(.poppins(.headline))
                        .textInputAutocapitalization(.words)
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 52)
                        .cardSurface(radius: AppTheme.compactRadius)
                }

                VStack(alignment: .leading, spacing: 13) {
                    DashboardSectionHeader("Symbol")

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 48), spacing: 11)],
                        spacing: 11
                    ) {
                        ForEach(ExpenseManager.availableCategorySymbols, id: \.self) { symbol in
                            Button {
                                withAnimation(.snappy(duration: 0.18)) {
                                    selectedSymbol = symbol
                                }
                            } label: {
                                Image(systemName: symbol)
                                    .font(.poppins(size: 16, weight: .semibold))
                                    .foregroundStyle(selectedSymbol == symbol ? Color.white : Color.primary)
                                    .frame(width: 48, height: 48)
                                    .background(
                                        selectedSymbol == symbol ? Color.black : AppTheme.subtleFill,
                                        in: RoundedRectangle(cornerRadius: 14)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(symbol)
                            .accessibilityAddTraits(selectedSymbol == symbol ? .isSelected : [])
                        }
                    }
                }

                Button(action: submitCategory) {
                    Text("Add Category")
                        .font(.poppins(.headline))
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
    }

    /// Adds the category only after manager-level name and symbol validation succeeds.
    private func submitCategory() {
        if manager.addCategory(name: categoryName, symbol: selectedSymbol) {
            dismiss()
        }
    }
}

#Preview("Profile") {
    ProfileTabView()
        .environmentObject(ExpenseManager.previewPopulated)
        .preferredColorScheme(.light)
}
