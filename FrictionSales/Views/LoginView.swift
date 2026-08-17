import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var isAcceptedTerms = false
    @State private var isLoginMode = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Logo placeholder
                HStack {
                    Spacer()
                    Text("L")
                        .font(.system(size: 24, weight: .light, design: .serif))
                        .italic()
                        .frame(width: 60, height: 60)
                        .background(Color(.systemGray6), in: Circle())
                    Spacer()
                }
                .padding(.top, 40)
                .padding(.bottom, 20)
                
                Text(isLoginMode ? "Log in" : "Sign up")
                    .font(.poppins(size: 36, weight: .regular))
                    .padding(.bottom, 8)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.poppins(size: 14, weight: .semibold))
                        
                        TextField("Your email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                    }
                    
                    // Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.poppins(size: 14, weight: .semibold))
                        
                        SecureField("Enter your password", text: $password)
                            .padding()
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                    }
                    
                    if !isLoginMode {
                        // Terms checkbox
                        Button {
                            isAcceptedTerms.toggle()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: isAcceptedTerms ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundStyle(isAcceptedTerms ? Color(uiColor: .darkGray) : Color(.systemGray4))
                                
                                Text("I accept the terms and privacy policy")
                                    .font(.poppins(size: 14, weight: .medium))
                                    .foregroundStyle(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }
                
                if let errorMessage {
                    Text(errorMessage)
                        .font(.poppins(size: 14, weight: .medium))
                        .foregroundStyle(.red)
                }
                
                // Submit Button
                Button {
                    Task { await submit() }
                } label: {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(isLoginMode ? "Log in" : "Sign up")
                            .font(.poppins(size: 16, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(uiColor: .darkGray), in: RoundedRectangle(cornerRadius: 28))
                .foregroundStyle(.white)
                .disabled(isLoading || !canSubmit)
                .padding(.top, 8)
                
                // Social Logins
                VStack(spacing: 24) {
                    HStack {
                        Rectangle().frame(height: 1).foregroundStyle(Color(.systemGray5))
                        Text(isLoginMode ? "Or Log in with" : "Or Register with")
                            .font(.poppins(size: 14))
                            .foregroundStyle(.tertiary)
                            .layoutPriority(1)
                        Rectangle().frame(height: 1).foregroundStyle(Color(.systemGray5))
                    }
                    
                    HStack(spacing: 16) {
                        socialButton(icon: "f.square.fill", color: .blue)
                        socialButton(icon: "g.circle.fill", color: .red) // Generic google representation
                        socialButton(icon: "applelogo", color: .black)
                    }
                }
                .padding(.top, 16)
                
                Spacer(minLength: 40)
                
                // Toggle mode
                HStack(spacing: 4) {
                    Spacer()
                    Text(isLoginMode ? "Don't have an account?" : "Already have an account?")
                        .font(.poppins(size: 14))
                        .foregroundStyle(.secondary)
                    
                    Button {
                        withAnimation {
                            isLoginMode.toggle()
                            errorMessage = nil
                        }
                    } label: {
                        Text(isLoginMode ? "Sign up" : "Log in")
                            .font(.poppins(size: 14, weight: .bold))
                            .underline()
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                }
            }
            .padding(24)
        }
        .background(Color.white.ignoresSafeArea())
    }
    
    private var canSubmit: Bool {
        guard !email.isEmpty, !password.isEmpty else { return false }
        if !isLoginMode {
            return isAcceptedTerms
        }
        return true
    }
    
    private func submit() async {
        isLoading = true
        errorMessage = nil
        do {
            if isLoginMode {
                try await authManager.signInWithEmail(email: email, password: password)
            } else {
                try await authManager.signUpWithEmail(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    private func socialButton(icon: String, color: Color) -> some View {
        Button { } label: {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
