import SwiftUI

struct ManageProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var manager: ExpenseManager
    
    @State private var draftName = ""
    
    private var canSaveName: Bool {
        manager.canUpdateProfileName(draftName)
            && draftName.trimmingCharacters(in: .whitespacesAndNewlines) != manager.profileName
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Profile Name")
                        .font(.poppins(size: 14, weight: .semibold))
                    
                    TextField("Enter your name", text: $draftName)
                        .font(.poppins(.headline))
                        .textInputAutocapitalization(.words)
                        .padding()
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                    
                    Text("This name will be displayed in your profile and synced to the cloud.")
                        .font(.poppins(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                
                Button {
                    saveProfileName()
                } label: {
                    Text("Save Profile")
                        .font(.poppins(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(canSaveName ? Color.black : Color(.systemGray4), in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canSaveName)
                .padding(.top, 16)
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Manage Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            draftName = manager.profileName
        }
    }
    
    private func saveProfileName() {
        if manager.updateProfileName(draftName) {
            dismiss()
        }
    }
}

#Preview {
    NavigationView {
        ManageProfileView()
            .environmentObject(ExpenseManager.previewPopulated)
    }
}
