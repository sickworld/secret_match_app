import SwiftUI
import Combine

struct LoginView: View {
    @State private var number: String = ""
    @EnvironmentObject var api: APIService
    @State private var showKeyboard = false
    @State private var isLoading = false

    var body: some View {
        ZStack {
            // Hintergrundbild
            Image("bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Inhalt
            VStack {
                Spacer()

                VStack(spacing: 20) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 170)

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

                    Button(action: {
                        Task {
                            isLoading = true
                            do {
                                try await api.login(number: number)
                            } catch {
                                print("Login fehlgeschlagen: \(error.localizedDescription)")
                            }
                            isLoading = false
                        }
                    }) {
                        Text("Einloggen")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#a33c5e"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .font(.headline)
                    }
                    .frame(width: 500)
                }
                .padding()
                .background(Color(hex: "#3c0d1f").opacity(0.92))
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)

                Spacer()
            }

            // 🔄 Loading Overlay
            if isLoading {
                LoadingOverlay(message: "Wird angemeldet…")
                    .zIndex(10)
            }

            // 🔢 Tastatur-Overlay
            if showKeyboard {
                // Transparente Fläche, die das Keyboard schließt
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showKeyboard = false
                        }
                    }
                    .zIndex(20)

                // Zentrierte Tastaturbox
                VStack {
                    Spacer()
                    VStack(spacing: 10) {
                        CustomNumberKeyboard(text: $number) {
                            withAnimation {
                                showKeyboard = false
                            }
                        }
                        .frame(maxWidth: 320)
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
    }
}
