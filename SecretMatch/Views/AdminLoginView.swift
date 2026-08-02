import SwiftUI
import LocalAuthentication

struct AdminLoginView: View {
    @Binding var isPresented: Bool
    var allowsDismiss = true
    @EnvironmentObject var api: APIService

    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var biometricType: LABiometryType = .none
    @State private var didRequestBiometrics = false

    var body: some View {
        ZStack {
            BrandBackground()

            GeometryReader { proxy in
                ScrollView {
                    VStack {
                if allowsDismiss {
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
                }

                Spacer(minLength: allowsDismiss ? 30 : 22)

                VStack(spacing: 34) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 230, height: 150)
                        .shadow(color: SecretMatchTheme.primary.opacity(0.18), radius: 18)

                    VStack(spacing: 12) {
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

                    if api.hasSavedAdminSession && biometricType != .none {
                        Button(action: performBiometricLogin) {
                            HStack {
                                Image(systemName: biometricIcon)
                                Text("Mit \(biometricName) anmelden")
                                Spacer()
                            }
                        }
                        .buttonStyle(SecretPrimaryButtonStyle(fontSize: 19, minHeight: 68))
                        .disabled(isLoading)

                        Text("Oder Admin-Passwort verwenden")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SecretMatchTheme.muted)
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
                .secretCard(cornerRadius: 30, padding: allowsDismiss ? 50 : 28)
                .padding(.horizontal, allowsDismiss ? 28 : 18)

                Spacer(minLength: 34)
                    }
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
            }
        }
        .onAppear {
            detectBiometrics()
            guard !didRequestBiometrics, api.hasSavedAdminSession else { return }
            didRequestBiometrics = true
            performBiometricLogin()
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

    private var biometricName: String {
        biometricType == .faceID ? "Face ID" : "Touch ID"
    }

    private var biometricIcon: String {
        biometricType == .faceID ? "faceid" : "touchid"
    }

    private func detectBiometrics() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricType = .none
            return
        }
        biometricType = context.biometryType
    }

    private func performBiometricLogin() {
        guard api.hasSavedAdminSession, !isLoading else { return }

        let context = LAContext()
        context.localizedCancelTitle = "Passwort verwenden"
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let authenticated = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: "Admin-Bereich von Match&Play entsperren"
                )
                isLoading = false
                if authenticated && api.unlockSavedAdminSession() {
                    isPresented = false
                }
            } catch let error as LAError {
                isLoading = false
                if error.code != .userCancel && error.code != .appCancel && error.code != .systemCancel {
                    errorMessage = "\(biometricName) nicht möglich. Bitte Admin-Passwort verwenden."
                }
            } catch {
                isLoading = false
                errorMessage = "Biometrische Anmeldung nicht möglich."
            }
        }
    }
}
