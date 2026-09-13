@testable import SecretMatch
import XCTest

@MainActor
final class ParticipantLoginDecodingTests: XCTestCase {
    func testParticipantLoginDecodesSnakeCaseResponse() throws {
        let response = try decode(
            ParticipantLoginResponse.self,
            json: """
            {
              "number": "007",
              "needs_pin": true,
              "needs_gender": false,
              "event_id": "event-42"
            }
            """
        )

        XCTAssertEqual(response.number, "007")
        XCTAssertTrue(response.needsPin)
        XCTAssertFalse(response.needsGender)
        XCTAssertEqual(response.eventID, "event-42")
    }

    func testParticipantLoginDefaultsMissingNeedsPinToFalse() throws {
        let response = try decode(
            ParticipantLoginResponse.self,
            json: #"{"needs_gender":true}"#
        )

        XCTAssertNil(response.number)
        XCTAssertFalse(response.needsPin)
        XCTAssertTrue(response.needsGender)
        XCTAssertNil(response.eventID)
    }

    func testParticipantLoginRejectsMissingNeedsGender() {
        XCTAssertThrowsError(
            try decode(ParticipantLoginResponse.self, json: #"{"needs_pin":false}"#)
        )
    }
}

@MainActor
final class ManagedContentDecodingTests: XCTestCase {
    func testScreensaverItemDecodesServerKeysAndDefaultBackdrop() throws {
        let item = try decode(
            ScreensaverMediaItem.self,
            json: """
            {
              "id": "123e4567-e89b-12d3-a456-426614174000",
              "attachment_id": 17,
              "title": "Sponsor",
              "image_url": "https://example.com/sponsor.png",
              "show_in_screensaver": true,
              "show_as_sponsor": false,
              "display_seconds": 12,
              "enabled": true,
              "sort_order": 30,
              "revision": 2,
              "updated_at": 123456
            }
            """
        )

        XCTAssertEqual(item.attachmentID, 17)
        XCTAssertEqual(item.imageURL, "https://example.com/sponsor.png")
        XCTAssertTrue(item.showInScreensaver)
        XCTAssertFalse(item.showAsSponsor)
        XCTAssertFalse(item.useLightBackground)
        XCTAssertEqual(item.displaySeconds, 12)
        XCTAssertEqual(item.sortOrder, 30)
        XCTAssertEqual(item.revision, 2)
    }

    func testScreensaverSettingsDecodeSnakeCase() throws {
        let settings = try decode(
            ScreensaverSettingsResponse.self,
            json: #"{"idle_seconds":90}"#
        )

        XCTAssertEqual(settings.idleSeconds, 90)
    }

    func testEventAnnouncementDecodesSchedulingFields() throws {
        let announcement = try decode(
            EventAnnouncement.self,
            json: """
            {
              "id": "notice-1",
              "message": "Willkommen",
              "tone": "highlight",
              "enabled": true,
              "starts_at": 100,
              "ends_at": 200,
              "created_at": 50,
              "updated_at": 75,
              "live": true
            }
            """
        )

        XCTAssertEqual(announcement.id, "notice-1")
        XCTAssertEqual(announcement.startsAt, 100)
        XCTAssertEqual(announcement.endsAt, 200)
        XCTAssertTrue(announcement.live)
    }
}

@MainActor
final class CodablePersistenceTests: XCTestCase {
    func testPendingInteractionRoundTripsWithoutDataLoss() throws {
        let interaction = PendingInteraction(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            batchID: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
            senderNumber: "7",
            targetNumber: "42",
            type: "normal",
            kind: .match,
            message: "Hallo",
            createdAt: Date(timeIntervalSince1970: 1_000),
            retryCount: 2,
            nextAttemptAt: Date(timeIntervalSince1970: 1_030)
        )

        let data = try JSONEncoder().encode(interaction)
        let decoded = try JSONDecoder().decode(PendingInteraction.self, from: data)

        XCTAssertEqual(decoded.id, interaction.id)
        XCTAssertEqual(decoded.batchID, interaction.batchID)
        XCTAssertEqual(decoded.senderNumber, "7")
        XCTAssertEqual(decoded.targetNumber, "42")
        XCTAssertEqual(decoded.kind, .match)
        XCTAssertEqual(decoded.message, "Hallo")
        XCTAssertEqual(decoded.retryCount, 2)
        XCTAssertEqual(decoded.nextAttemptAt, interaction.nextAttemptAt)
    }

    func testPendingTelemetryUsesExpectedServerKeys() throws {
        let event = PendingTelemetryEvent(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            occurredAt: "2026-09-13T20:00:00Z",
            severity: "info",
            category: "queue",
            eventType: "interaction_queued",
            deviceID: "device-1",
            targetNumber: "42",
            requestID: "request-1",
            status: "queued",
            context: ["kind": "match"]
        )

        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(event)) as? [String: Any]
        )

        XCTAssertEqual(object["event_type"] as? String, "interaction_queued")
        XCTAssertEqual(object["device_id"] as? String, "device-1")
        XCTAssertEqual(object["target_number"] as? String, "42")
        XCTAssertEqual(object["request_id"] as? String, "request-1")
        XCTAssertNil(object["eventType"])
    }
}

@MainActor
final class AdminPresentationLogicTests: XCTestCase {
    func testLogContextValuesDecodeAndFormatSupportedTypes() throws {
        let values = try decode(
            [String: LogContextValue].self,
            json: #"{"text":"ok","whole":3,"decimal":2.5,"flag":true,"items":["a","b"],"other":null}"#
        )

        XCTAssertEqual(values["text"]?.displayValue, "ok")
        XCTAssertEqual(values["whole"]?.displayValue, "3")
        XCTAssertEqual(values["decimal"]?.displayValue, "2.5")
        XCTAssertEqual(values["flag"]?.displayValue, "ja")
        XCTAssertEqual(values["items"]?.displayValue, "a, b")
        XCTAssertEqual(values["other"]?.displayValue, "–")
    }

    func testBillboardStatusPresentsResolutionAndMode() {
        let status = AdminBillboardStatus(
            billboardID: "board-1",
            name: "TV",
            lastSeen: 0,
            online: true,
            width: 1920,
            height: 1080,
            mode: "top"
        )

        XCTAssertEqual(status.resolution, "1920 × 1080")
        XCTAssertEqual(status.modeLabel, "Top 16")
        XCTAssertEqual(status.lastSeenDescription, "noch kein Signal")
    }

    func testTopPersonMapsKnownAndUnknownGenderValues() {
        XCTAssertEqual(TopPerson(number: "1", gender: "female").genderSymbol, "♀")
        XCTAssertEqual(TopPerson(number: "2", gender: "male").genderSymbol, "♂")
        XCTAssertEqual(TopPerson(number: "3", gender: nil).genderSymbol, "–")
    }
}

@MainActor
private func decode<Value: Decodable>(_ type: Value.Type, json: String) throws -> Value {
    try JSONDecoder().decode(type, from: Data(json.utf8))
}
