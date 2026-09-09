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
            SecretMatchTheme.background
                .ignoresSafeArea()

            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
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
                        AdminKeyboardTextField(
                            title: "Admin-Passwort",
                            text: $password,
                            keyboard: .text(maxCharacters: 128),
                            keyboardTitle: "Admin-Passwort eingeben",
                            isSecure: !showPassword,
                            doneLabel: "Anmelden",
                            onSubmit: performLogin
                        )
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .textContentType(.password)
                        .submitLabel(.go)

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
                            .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
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
                        .padding(.horizontal, allowsDismiss ? 50 : 32)
                        .padding(.vertical, 36)
                    }
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
                .overlay(alignment: .topTrailing) {
                    if allowsDismiss {
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .frame(width: 54, height: 54)
                                .background(SecretMatchTheme.surfaceRaised)
                                .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
                        }
                        .accessibilityLabel("Admin Login schließen")
                        .padding(28)
                    }
                }
            }
        }
        .onAppear {
            detectBiometrics()
            guard !didRequestBiometrics, api.hasSavedAdminSession else { return }
            didRequestBiometrics = true
            performBiometricLogin()
        }
        .buttonBorderShape(.roundedRectangle(radius: SecretMatchTheme.cornerRadius))
        .tint(SecretMatchTheme.primary)
    }

    private func performLogin() {
        guard !password.isEmpty, !isLoading else { return }

        errorMessage = nil
        Task {
            isLoading = true
            let result = await api.adminLogin(password: password)
            isLoading = false

            switch result {
            case .success:
                isPresented = false
            case .invalidCredentials:
                errorMessage = "Falsches Passwort"
            case .sessionExpired:
                errorMessage = "Die Admin-Sitzung ist abgelaufen. Bitte erneut anmelden."
            case .connectionFailed:
                errorMessage = "Anmeldung gerade nicht möglich. Bitte Internetverbindung prüfen."
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
                guard authenticated else {
                    isLoading = false
                    return
                }

                let result = await api.resumeSavedAdminSession(authenticationContext: context)
                isLoading = false
                switch result {
                case .success:
                    isPresented = false
                case .invalidCredentials, .sessionExpired:
                    errorMessage = "Die gespeicherte Anmeldung ist abgelaufen. Bitte gib das Admin-Passwort einmal neu ein."
                case .connectionFailed:
                    errorMessage = "\(biometricName) war erfolgreich, aber der Server ist gerade nicht erreichbar. Bitte Verbindung prüfen."
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
