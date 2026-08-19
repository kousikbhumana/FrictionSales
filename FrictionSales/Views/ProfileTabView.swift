import SwiftUI
import FirebaseAuth

struct ProfileTabView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var manager: ExpenseManager
    
    @State private var isPresentingCurrencyPicker = false
    @State private var isPresentingDeleteAlert = false
    @State private var isPresentingResetAlert = false
    
    private var displayEmail: String {
        authManager.user?.email ?? "Not signed in"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Header Card
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 64, height: 64)
                            .foregroundStyle(Color(.systemGray3))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(manager.profileName)
                                .font(.poppins(size: 20, weight: .semibold))
                                .foregroundStyle(.primary)
                            
                            Text(displayEmail)
                                .font(.poppins(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(20)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                    
                    // Account Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Account")
                            .font(.poppins(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 0) {
                            NavigationLink {
                                ManageProfileView()
                            } label: {
                                ProfileRow(icon: "person.crop.circle", title: "Manage Profile")
                            }
                            
                            Divider().padding(.leading, 56)
                            
                            NavigationLink {
                                SecuritySettingsView()
                            } label: {
                                ProfileRow(icon: "lock", title: "Password & Security")
                            }
                            
                            Divider().padding(.leading, 56)
                            
                            ProfileRow(icon: "bell", title: "Notifications")
                        }
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 24)
                    }
                    
                    // App Settings Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("App Settings")
                            .font(.poppins(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 0) {
                            Button {
                                isPresentingCurrencyPicker = true
                            } label: {
                                ProfileRow(icon: "dollarsign.circle", title: "Currency", value: manager.selectedCurrency.code)
                            }
                        }
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 24)
                    }
                    
                    // Support Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Support")
                            .font(.poppins(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 0) {
                            Button {
                                isPresentingResetAlert = true
                            } label: {
                                ProfileRowAction(icon: "arrow.triangle.2.circlepath", title: "Reset App Data", color: .orange)
                            }
                            
                            Divider().padding(.leading, 56)
                            
                            Button {
                                isPresentingDeleteAlert = true
                            } label: {
                                ProfileRowAction(icon: "trash", title: "Delete Account", color: .red)
                            }
                            
                            Divider().padding(.leading, 56)
                            
                            Button {
                                do {
                                    try authManager.signOut()
                                    manager.resetApp() // clear local data on sign out
                                } catch {
                                    print("Error signing out: \(error)")
                                }
                            } label: {
                                ProfileRowAction(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", color: .red)
                            }
                        }
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer(minLength: 100) // Space for the floating bottom bar
                }
                .padding(.top, 16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isPresentingCurrencyPicker) {
                CurrencyPickerSheet()
                    .environmentObject(manager)
            }
            .alert("Delete Account", isPresented: $isPresentingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            manager.resetApp() // Wipe cloud and local
                            try await authManager.deleteAccount() // Wipe auth
                        } catch {
                            print("Error deleting account: \(error)")
                        }
                    }
                }
            } message: {
                Text("This will permanently delete your account and all your synced expense data. This action cannot be undone.")
            }
            .alert("Reset App Data", isPresented: $isPresentingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    manager.resetApp()
                }
            } message: {
                Text("This will erase all your local expenses and wipe your cloud backup. Your account will remain active.")
            }
        }
    }
}

/// Reusable row component for the Profile screen
private struct ProfileRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.primary)
                .frame(width: 24)
            
            Text(title)
                .font(.poppins(size: 16, weight: .medium))
                .foregroundStyle(.primary)
            
            Spacer()
            
            if let value {
                Text(value)
                    .font(.poppins(size: 14))
                    .foregroundStyle(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(.systemGray3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

private struct ProfileRowAction: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(title)
                .font(.poppins(size: 16, weight: .medium))
                .foregroundStyle(color)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
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
                Text("Choose Currency")
                    .font(.poppins(size: 20, weight: .bold))
                    .padding(.top, 24)
                    .padding(.bottom, 8)

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
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))

                ForEach(filteredCurrencies) { currency in
                    Button {
                        manager.updateCurrency(currency)
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Text(currency.symbol)
                                .font(.poppins(.headline))
                                .frame(width: 44, height: 44)
                                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))

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
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
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
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
    }
}

#Preview {
    ProfileTabView()
        .environmentObject(AuthManager())
        .environmentObject(ExpenseManager.previewPopulated)
}
