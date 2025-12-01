import SwiftUI
import Combine

struct LoginView: View {
    @State private var number: String = ""
    @EnvironmentObject var api: APIService

    var body: some View {
        ZStack {
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
                        .frame(width: 200, height: 170)

                    TextField("", text: $number)
                        .placeholder(when: number.isEmpty) {
                            Text("Deine Nummer eingeben")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .keyboardType(.numberPad)
                        .padding()
                        .frame(width: 280, height: 55)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        )
                    
                    Button(action: {
                        Task {
                            do {
                                try await api.login(number: number)
                            } catch {
                                print("Login fehlgeschlagen: \(error.localizedDescription)")
                            }
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
                    .frame(width: 280)
                }
                .padding()
                .background(Color(hex: "#3c0d1f").opacity(0.92)) // 🔥 Burgundy Box
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)

                Spacer()
            }
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
