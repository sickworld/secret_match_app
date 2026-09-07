import UIKit
import UserNotifications

final class SecretMatchAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task { @MainActor in
            await APIService.shared.registerAdminPushToken(token, environment: AdminPushNotifications.environment)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Registration can fail temporarily or in Simulator builds. No sensitive error details are logged.
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}

enum AdminPushNotifications {
    static var environment: String {
#if DEBUG
        "sandbox"
#else
        "production"
#endif
    }

    @MainActor
    static func requestAuthorizationAndRegister() async {
#if ADMIN_APP
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) == true
        guard granted else {
            await APIService.shared.unregisterAdminPushToken()
            return
        }
        UIApplication.shared.registerForRemoteNotifications()
#endif
    }
}
