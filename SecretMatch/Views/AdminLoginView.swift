import SwiftUI

struct AdminLoginView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var api: APIService

    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            // Hintergrund wie überall sonst
            Image("bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

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

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button {
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
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Admin anmelden")
                            .fontWeight(.bold)
                    }
                }
                .buttonStyle(SidebarButtonStyle())

                Button("Abbrechen") {
                    isPresented = false
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 4)
                .buttonStyle(SidebarButtonStyle())

            }
            .padding(30)
            .frame(maxWidth: 360)
            .background(Color(hex: "#3c0d1f").opacity(0.95))
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.4), radius: 25)
        }
    }
}
