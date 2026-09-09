import Foundation
import LocalAuthentication
import Security

enum AdminSessionStore {
    private static let tokenAccount = "admin-session-token"
    private static let biometricCredentialAccount = "admin-biometric-credential"
    private static let biometricCredentialMarker = "secretmatch.admin-biometric-credential"
    private static var service: String {
        "\(Bundle.main.bundleIdentifier ?? "com.SecretMatch").admin-session"
    }

    static func loadToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenAccount,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]

        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    static func saveToken(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenAccount
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            attributes.forEach { item[$0.key] = $0.value }
            SecItemAdd(item as CFDictionary, nil)
        }
    }

    static func clearToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenAccount
        ]
        SecItemDelete(query as CFDictionary)
    }

    static var hasBiometricCredential: Bool {
        UserDefaults.standard.bool(forKey: biometricCredentialMarker)
    }

    @discardableResult
    static func saveBiometricCredential(_ password: String) -> Bool {
        guard !password.isEmpty, let data = password.data(using: .utf8) else { return false }
        var accessControlError: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            .biometryCurrentSet,
            &accessControlError
        ) else {
            return false
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: biometricCredentialAccount
        ]
        let deletionStatus = SecItemDelete(query as CFDictionary)
        guard deletionStatus == errSecSuccess || deletionStatus == errSecItemNotFound else {
            return false
        }

        let item: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: biometricCredentialAccount,
            kSecValueData as String: data,
            kSecAttrAccessControl as String: accessControl
        ]
        let saved = SecItemAdd(item as CFDictionary, nil) == errSecSuccess
        UserDefaults.standard.set(saved, forKey: biometricCredentialMarker)
        return saved
    }

    static func loadBiometricCredential(authenticationContext: LAContext) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: biometricCredentialAccount,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: authenticationContext
        ]

        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    static func clearBiometricCredential() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: biometricCredentialAccount
        ]
        SecItemDelete(query as CFDictionary)
        UserDefaults.standard.removeObject(forKey: biometricCredentialMarker)
    }
}
