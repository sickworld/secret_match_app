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
            Color(hex: "#200813")
                .ignoresSafeArea()

            Image("bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 20) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 270)
                        .onLongPressGesture(minimumDuration: 3) {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showAdminLogin = true
                        }
                    
                    Text(number.isEmpty ? "Deine Nummer eingeben" : number)
                        .foregroundColor(number.isEmpty ? .white.opacity(0.6) : .white)
                        .frame(width: 500, height: 55)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(12)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        )
                        .onTapGesture {
                            showKeyboard = true
                        }

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.white)
                            .font(.footnote.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(width: 500)
                            .background(Color.red.opacity(0.28))
                            .cornerRadius(10)
                    }

                    Button(action: submitLogin) {
                        Text("Einloggen")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#a33c5e"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .font(.headline)
                    }
                    .frame(width: 500)
                    .disabled(isLoading || number.isEmpty)
                    .opacity(number.isEmpty ? 0.55 : 1)
                }
                .padding()
                .background(Color(hex: "#3c0d1f").opacity(0.92))
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)

                Spacer()
            }

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
        }.sheet(isPresented: $showAdminLogin) {
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
