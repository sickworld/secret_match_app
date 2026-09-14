import LocalAuthentication
@testable import SecretMatch
import XCTest

@MainActor
final class PersistenceCoverageTests: XCTestCase {
    func testAdminBiometricMarkerAndEmptyCredentialAreHandledWithoutPrompt() {
        let defaults = UserDefaults.standard
        let marker = "secretmatch.admin-biometric-credential"
        let previousMarker = defaults.object(forKey: marker)
        defer {
            if let previousMarker {
                defaults.set(previousMarker, forKey: marker)
            } else {
                defaults.removeObject(forKey: marker)
            }
        }

        defaults.set(true, forKey: marker)
        XCTAssertTrue(AdminSessionStore.hasBiometricCredential)
        XCTAssertFalse(AdminSessionStore.saveBiometricCredential(""))

        AdminSessionStore.clearToken()
        XCTAssertNil(AdminSessionStore.loadToken())
        AdminSessionStore.saveToken("coverage-token")
        AdminSessionStore.clearToken()

        let authenticationContext = LAContext()
        authenticationContext.interactionNotAllowed = true
        XCTAssertNil(AdminSessionStore.loadBiometricCredential(authenticationContext: authenticationContext))
        _ = AdminSessionStore.saveBiometricCredential("coverage-password")
        AdminSessionStore.clearBiometricCredential()
    }

    func testDeviceHeartbeatTokenUsesNormalizedRandomFormat() throws {
        let token = try XCTUnwrap(DeviceHeartbeatCredentialStore.loadOrCreateToken())

        XCTAssertEqual(token.count, 64)
        XCTAssertTrue(token.allSatisfy(\.isHexDigit))
        XCTAssertEqual(token, token.lowercased())
    }

    func testScreensaverCacheClampsIdleTimeAndRejectsInvalidCacheIdentifiers() throws {
        let defaults = UserDefaults.standard
        let key = "secretmatch.screensaver-idle-seconds.v1"
        let previousValue = defaults.object(forKey: key)
        defer {
            if let previousValue {
                defaults.set(previousValue, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }

        defaults.removeObject(forKey: key)
        XCTAssertEqual(ScreensaverMediaCache.loadIdleSeconds(), 60)

        ScreensaverMediaCache.storeIdleSeconds(1)
        XCTAssertEqual(ScreensaverMediaCache.loadIdleSeconds(), 15)

        ScreensaverMediaCache.storeIdleSeconds(999)
        XCTAssertEqual(ScreensaverMediaCache.loadIdleSeconds(), 600)

        let item = try JSONDecoder().decode(
            ScreensaverMediaItem.self,
            from: Data(
                #"{"id":"invalid","attachment_id":null,"title":"Test","image_url":"https://example.com/test.png","show_in_screensaver":true,"show_as_sponsor":false,"display_seconds":8,"enabled":true,"sort_order":1,"revision":1}"#.utf8
            )
        )

        XCTAssertEqual(item.remoteURL?.host, "example.com")
        XCTAssertFalse(ScreensaverMediaCache.containsImage(for: item))
        XCTAssertThrowsError(
            try ScreensaverMediaCache.storeCompleteCatalog([item], downloadedData: [:])
        )
    }

    func testAdminFeedbackDefaultsUnsupportedValuesAndSentActionKeepsPayload() throws {
        let feedback = try JSONDecoder().decode(
            AdminFeedback.self,
            from: Data(#"{"id":17,"rating":true,"created_at":23}"#.utf8)
        )

        XCTAssertEqual(feedback.id, "17")
        XCTAssertNil(feedback.rating)
        XCTAssertNil(feedback.functionalityRating)
        XCTAssertNil(feedback.easeOfUseRating)
        XCTAssertNil(feedback.designRating)
        XCTAssertEqual(feedback.createdAt, "23")

        let timestamp = Date(timeIntervalSince1970: 123)
        let action = SentAction(toNumber: "42", type: "bjob", timestamp: timestamp)
        XCTAssertNotEqual(action.id, UUID())
        XCTAssertEqual(action.toNumber, "42")
        XCTAssertEqual(action.type, "bjob")
        XCTAssertEqual(action.timestamp, timestamp)

        XCTAssertEqual(AdminPushNotifications.environment, "sandbox")
        XCTAssertEqual(
            AdminFeedbackLoadError.invalidResponse.errorDescription,
            "Der Feedback-Server hat nicht korrekt geantwortet."
        )
        XCTAssertEqual(
            AdminFeedbackLoadError.sessionExpired.errorDescription,
            "Die Admin-Sitzung ist abgelaufen. Bitte erneut anmelden."
        )
        XCTAssertEqual(
            AdminFeedbackLoadError.server(statusCode: 503).errorDescription,
            "Feedback konnte wegen eines Serverfehlers nicht geladen werden (HTTP 503)."
        )
        XCTAssertEqual(
            AdminFeedbackLoadError.invalidPayload.errorDescription,
            "Die Feedback-Antwort hat ein unbekanntes Format."
        )
    }
}
