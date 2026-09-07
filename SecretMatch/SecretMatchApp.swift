import SwiftUI

@main
struct SecretMatchApp: App {
    @UIApplicationDelegateAdaptor(SecretMatchAppDelegate.self) private var appDelegate
    @StateObject private var api = APIService.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ZStack {
#if ADMIN_APP
                Group {
                    if api.isAdmin {
                        AdminMainView()
                    } else {
                        AdminLoginView(isPresented: .constant(true), allowsDismiss: false)
                    }
                }
                .environmentObject(api)
                .preferredColorScheme(.dark)
#else
                Group {
                    if api.isAdmin {
                        AdminMainView()
                    } else if api.isLoggedIn {
                        MatchView()
                    } else {
                        LoginView()
                    }
                }
                .environmentObject(api)
                .preferredColorScheme(.dark)
#endif
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                ConnectionStatusBanner(
                    state: api.connectionState,
                    isChecking: api.isCheckingConnection,
                    retry: {
                        Task {
                            await api.checkConnection()
                        }
                    }
                )
                .animation(.easeInOut(duration: 0.2), value: api.connectionState)
            }
            .task {
                api.applicationDidBecomeActive()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                UIApplication.shared.isIdleTimerDisabled = true
                api.applicationDidBecomeActive()
            case .background:
                api.applicationDidEnterBackground()
            default:
                break
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
