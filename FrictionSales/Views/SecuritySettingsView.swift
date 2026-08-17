import SwiftUI

struct SecuritySettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    
    @State private var newEmail = ""
    @State private var newPassword = ""
    @State private var isLoading = false
    @State private var successMessage: String?
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Change Email")
                        .font(.poppins(size: 14, weight: .semibold))
                    
                    TextField("New email address", text: $newEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                    
                    Button {
                        Task { await updateEmail() }
                    } label: {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Update Email")
                                .font(.poppins(size: 14, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                    .disabled(isLoading || newEmail.isEmpty)
                    .padding(.top, 4)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Change Password")
                        .font(.poppins(size: 14, weight: .semibold))
                    
                    SecureField("New password (min 6 characters)", text: $newPassword)
                        .padding()
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                    
                    Button {
                        Task { await updatePassword() }
                    } label: {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Update Password")
                                .font(.poppins(size: 14, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                    .disabled(isLoading || newPassword.isEmpty)
                    .padding(.top, 4)
                }
                
                if let successMessage {
                    Text(successMessage)
                        .font(.poppins(size: 14, weight: .medium))
                        .foregroundStyle(.green)
                }
                
                if let errorMessage {
                    Text(errorMessage)
                        .font(.poppins(size: 14, weight: .medium))
                        .foregroundStyle(.red)
                }
                
                Text("Note: Changing your email or password requires you to have signed in recently. If you encounter an error, sign out and sign back in.")
                    .font(.poppins(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.top, 16)
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Password & Security")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func updateEmail() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            try await authManager.updateEmail(to: newEmail)
            successMessage = "Email updated successfully!"
            newEmail = ""
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    private func updatePassword() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            try await authManager.updatePassword(to: newPassword)
            successMessage = "Password updated successfully!"
            newPassword = ""
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    NavigationView {
        SecuritySettingsView()
            .environmentObject(AuthManager())
    }
}
