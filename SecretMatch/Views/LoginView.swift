import SwiftUI
import Combine

struct LoginView: View {
    @State private var number: String = ""
    @EnvironmentObject var api: APIService
    @State private var showKeyboard = false
    @State private var isLoading = false
    @State private var showAdminLogin = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            BrandBackground()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 190)
                        .shadow(color: SecretMatchTheme.primary.opacity(0.22), radius: 24)
                        .onLongPressGesture(minimumDuration: 3) {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showAdminLogin = true
                        }

                    VStack(spacing: 7) {
                        Text("DEIN EVENT. DEIN MATCH.")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .tracking(2.2)
                            .foregroundStyle(SecretMatchTheme.secondary)

                        Text("Bereit für Match&Play?")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(SecretMatchTheme.text)

                        Text("Gib deine Event-Nummer ein und entdecke, wer mit dir matcht.")
                            .font(.subheadline)
                            .foregroundStyle(SecretMatchTheme.muted)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 9) {
                        Text(number.isEmpty ? "Nummer eingeben" : number)
                            .foregroundStyle(number.isEmpty ? SecretMatchTheme.muted : SecretMatchTheme.text)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .secretInput(highlighted: showKeyboard)
                            .onTapGesture {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    showKeyboard = true
                                }
                            }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(SecretMatchTheme.text)
                            .font(.footnote.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(SecretMatchTheme.danger.opacity(0.16))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(SecretMatchTheme.danger.opacity(0.4)))
                    }

                    Button(action: submitLogin) {
                        HStack {
                            Text("Event betreten")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(SecretPrimaryButtonStyle())
                    .disabled(isLoading || number.isEmpty)
                    .opacity(number.isEmpty ? 0.55 : 1)
                }
                .frame(maxWidth: 500)
                .secretCard(cornerRadius: 24, padding: 32)

                Spacer()
            }
            .padding(28)

            if isLoading {
                LoadingOverlay(message: "Wird angemeldet…")
                    .zIndex(10)
            }

            if showKeyboard {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showKeyboard = false
                        }
                    }
                    .zIndex(20)

                VStack {
                    Spacer()
                    VStack(spacing: 10) {
                        CustomNumberKeyboard(text: $number, doneLabel: "Einloggen") {
                            submitLogin()
                        }
                        .frame(maxWidth: 460)
                        .cornerRadius(16)
                        .shadow(radius: 20)
                    }
                    .padding()
                    Spacer()
                }
                .zIndex(30)
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.24), value: showKeyboard)
        .sheet(isPresented: $showAdminLogin) {
            AdminLoginView(isPresented: $showAdminLogin)
                .environmentObject(api)
        }
    }

    private func submitLogin() {
        guard !number.isEmpty, !isLoading else { return }

        showKeyboard = false
        errorMessage = nil
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                try await api.login(number: number)
            } catch {
                errorMessage = "Login fehlgeschlagen. Bitte Nummer prüfen und erneut versuchen."
            }
        }
    }
}
