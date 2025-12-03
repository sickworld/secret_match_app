import SwiftUI

@main
struct SecretMatchApp: App {
    @StateObject private var api = APIService.shared
    @State private var isLoading = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Image("bg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                if isLoading {
                    VStack(spacing: 20) {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)

                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    .zIndex(999)
                } else {
                    if api.isLoggedIn {
                        MatchView()
                    } else {
                        LoginView()
                    }
                }
            }
            .environmentObject(api)
            .onAppear {
                Task {
                    // Hier kannst du ggf. eine API-Statusprüfung einbauen
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // optional: Wartezeit simulieren
                    withAnimation {
                        isLoading = false
                    }
                }
            }
        }
    }
}
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.replacingOccurrences(of: "#", with: ""))
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
