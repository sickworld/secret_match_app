import SwiftUI

struct AdminLoginView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var api: APIService

    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            BrandBackground()

            VStack(spacing: 24) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160)
                    .shadow(color: SecretMatchTheme.primary.opacity(0.18), radius: 18)

                VStack(spacing: 6) {
                    Text("EVENT CONTROL")
                        .font(.caption2.bold())
                        .tracking(2)
                        .foregroundStyle(SecretMatchTheme.secondary)
                    Text("Admin Login")
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                SecureField("Admin Passwort", text: $password)
                    .foregroundStyle(.white)
                    .secretInput()
                    .textContentType(.password)
                    .submitLabel(.go)
                    .onSubmit(performLogin)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(SecretMatchTheme.danger)
                        .font(.caption)
                }

                Button(action: performLogin) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Admin anmelden")
                            .fontWeight(.bold)
                    }
                }
                .buttonStyle(SecretPrimaryButtonStyle())
                .disabled(password.isEmpty || isLoading)

                Button("Abbrechen") {
                    isPresented = false
                }
                .foregroundStyle(SecretMatchTheme.muted)
                .padding(.top, 4)
                .buttonStyle(SecretSecondaryButtonStyle())

            }
            .frame(maxWidth: 360)
            .secretCard(cornerRadius: 24, padding: 30)
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
