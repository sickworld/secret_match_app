import XCTest
@testable import SecretMatch

@MainActor
final class EventNumberFormattingTests: XCTestCase {
    func testNormalizationRemovesWhitespaceHashAndLeadingZeroes() {
        XCTAssertEqual("  #007 \n".normalizedEventNumber, "7")
        XCTAssertEqual("000".normalizedEventNumber, "0")
        XCTAssertEqual("42".normalizedEventNumber, "42")
        XCTAssertEqual("".normalizedEventNumber, "")
    }

    func testDisplayFormattingPadsShortNumericValues() {
        XCTAssertEqual("7".displayEventNumber, "007")
        XCTAssertEqual("#42".displayEventNumber, "042")
        XCTAssertEqual("123".displayEventNumber, "123")
    }

    func testDisplayFormattingDoesNotPadNonNumericValues() {
        XCTAssertEqual("A2".displayEventNumber, "A2")
    }
}

@MainActor
final class DefinitionTests: XCTestCase {
    func testLegacyMatchIDIsNormalizedCaseInsensitively() {
        XCTAssertEqual(MatchDefinition.normalizedID("F-"), "hot")
        XCTAssertEqual(MatchDefinition.normalizedID("f-"), "hot")
        XCTAssertEqual(MatchDefinition.normalizedID("normal"), "normal")
    }

    func testKnownMatchFallbackUsesConfiguredDefinition() {
        let definition = MatchDefinition.fallback(for: "F-")

        XCTAssertEqual(definition.id, "hot")
        XCTAssertEqual(definition.name, "Fuck-Match")
        XCTAssertEqual(definition.sortOrder, 20)
    }

    func testUnknownMatchFallbackRemainsUsable() {
        let definition = MatchDefinition.fallback(for: "special")

        XCTAssertEqual(definition.id, "special")
        XCTAssertEqual(definition.name, "Special")
        XCTAssertTrue(definition.enabled)
        XCTAssertEqual(definition.sortOrder, 999)
    }

    func testDefinitionTitlesIncludeEmojiOnlyWhenPresent() {
        var match = MatchDefinition.fallback(for: "normal")
        XCTAssertEqual(match.displayTitle, "❤️ Hot-Match")
        match.emoji = ""
        XCTAssertEqual(match.displayTitle, "Hot-Match")

        var action = ActionDefinition.fallback(for: "custom")
        XCTAssertEqual(action.displayTitle, "✨ Custom")
        action.emoji = ""
        XCTAssertEqual(action.displayTitle, "Custom")
    }

    func testKnownAndUnknownActionFallbacks() {
        XCTAssertEqual(ActionDefinition.fallback(for: "hjob"), ActionDefinition.fallbacks[1])

        let unknown = ActionDefinition.fallback(for: "wave")
        XCTAssertEqual(unknown.id, "wave")
        XCTAssertEqual(unknown.targetGender, "any")
        XCTAssertEqual(unknown.direction, "neutral")
        XCTAssertEqual(unknown.sortOrder, 999)
    }
}

@MainActor
final class InteractionQueueWordingTests: XCTestCase {
    func testShipmentCountHandlesMissingAndInvalidServerValues() {
        XCTAssertEqual(InteractionQueueWording.shipmentCount(reportedShipmentCount: nil, actionCount: 3), 3)
        XCTAssertEqual(InteractionQueueWording.shipmentCount(reportedShipmentCount: 0, actionCount: 3), 3)
        XCTAssertEqual(InteractionQueueWording.shipmentCount(reportedShipmentCount: 8, actionCount: 3), 3)
        XCTAssertEqual(InteractionQueueWording.shipmentCount(reportedShipmentCount: 2, actionCount: 3), 2)
        XCTAssertEqual(InteractionQueueWording.shipmentCount(reportedShipmentCount: 2, actionCount: 0), 0)
    }

    func testSummaryUsesCorrectSingularAndPluralWording() {
        XCTAssertEqual(
            InteractionQueueWording.summary(reportedShipmentCount: 1, actionCount: 1),
            "1 Versand mit 1 Aktion"
        )
        XCTAssertEqual(
            InteractionQueueWording.summary(reportedShipmentCount: 2, actionCount: 3),
            "2 Versandvorgänge mit 3 Aktionen"
        )
    }

    func testWaitingDescriptionMatchesShipmentCount() {
        XCTAssertEqual(
            InteractionQueueWording.waitingDescription(reportedShipmentCount: 1, actionCount: 2),
            "1 Versand mit 2 Aktionen wartet"
        )
        XCTAssertEqual(
            InteractionQueueWording.waitingDescription(reportedShipmentCount: 2, actionCount: 2),
            "2 Versandvorgänge mit 2 Aktionen warten"
        )
    }

    func testSubmissionMessageCombinesDeliveredAndQueuedResults() {
        let result = InteractionSubmissionResult(
            messages: ["Aktion gespeichert"],
            queuedCount: 2,
            actionRequestIDs: []
        )

        XCTAssertEqual(
            result.userMessage,
            "Aktion gespeichert\n1 Versand mit 2 Aktionen wartet sicher und geht automatisch raus, sobald die Verbindung wieder da ist."
        )
    }

    func testSubmissionMessageReturnsDeliveredMessagesWithoutQueueSuffix() {
        let result = InteractionSubmissionResult(
            messages: ["Match gespeichert", "Aktion gespeichert"],
            queuedCount: 0,
            actionRequestIDs: []
        )

        XCTAssertEqual(result.userMessage, "Match gespeichert\nAktion gespeichert")
    }
}
