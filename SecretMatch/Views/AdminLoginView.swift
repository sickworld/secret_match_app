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
                    .frame(width: 180)

                Text("Admin Login")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                SecureField("Admin Passwort", text: $password)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .textContentType(.password)
                    .submitLabel(.go)
                    .onSubmit(performLogin)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
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
                .buttonStyle(SidebarButtonStyle())
                .disabled(password.isEmpty || isLoading)

                Button("Abbrechen") {
                    isPresented = false
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 4)
                .buttonStyle(SidebarButtonStyle())

            }
            .padding(30)
            .frame(maxWidth: 360)
            .background(Color(hex: "#35070D").opacity(0.96))
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.4), radius: 25)
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
