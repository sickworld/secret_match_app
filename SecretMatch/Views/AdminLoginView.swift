import SwiftUI

struct AdminLoginView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var api: APIService

    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showPassword = false

    var body: some View {
        ZStack {
            BrandBackground()

            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .frame(width: 54, height: 54)
                            .background(SecretMatchTheme.surfaceRaised)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Admin Login schließen")
                }
                .padding(28)

                Spacer()

                VStack(spacing: 26) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 230, height: 150)
                        .shadow(color: SecretMatchTheme.primary.opacity(0.18), radius: 18)

                    VStack(spacing: 8) {
                        Text("EVENT CONTROL")
                            .font(.caption.bold())
                            .tracking(2.4)
                            .foregroundStyle(SecretMatchTheme.secondary)
                        Text("Admin-Bereich")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Melde dich an, um Event und Billboard zu verwalten.")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(SecretMatchTheme.muted)
                            .multilineTextAlignment(.center)
                    }

                    HStack {
                        Group {
                            if showPassword {
                                TextField("Admin-Passwort", text: $password)
                            } else {
                                SecureField("Admin-Passwort", text: $password)
                            }
                        }
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .textContentType(.password)
                        .submitLabel(.go)
                        .onSubmit(performLogin)

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .font(.title3)
                                .foregroundStyle(SecretMatchTheme.muted)
                                .frame(width: 48, height: 48)
                        }
                    }
                    .secretInput(highlighted: !password.isEmpty)

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(SecretMatchTheme.danger)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .padding(14)
                            .frame(maxWidth: .infinity)
                            .background(SecretMatchTheme.danger.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button(action: performLogin) {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            HStack {
                                Text("Admin anmelden")
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                        }
                    }
                    .buttonStyle(SecretPrimaryButtonStyle(fontSize: 20, minHeight: 76))
                    .disabled(password.isEmpty || isLoading)
                    .opacity(password.isEmpty ? 0.55 : 1)
                }
                .frame(maxWidth: 560)
                .secretCard(cornerRadius: 30, padding: 42)
                .padding(.horizontal, 28)

                Spacer()
            }
        }
    }

    private func performLogin() {
        guard !password.isEmpty, !isLoading else { return }

        errorMessage = nil
        Task {
            isLoading = true
            let success = await api.adminLogin(password: password)
            isLoading = false

            if success {
                isPresented = false
            } else {
                errorMessage = "Falsches Passwort"
            }
        }
    }
}
