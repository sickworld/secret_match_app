import SwiftUI
import XCTest
@testable import SecretMatch

@MainActor
final class ViewSmokeTests: XCTestCase {
    func testStaticInformationViewsRenderAtIPadSize() {
        assertRenders(AdminChangelogView())
        assertRenders(PrivacyNoticeView(isPresented: .constant(true)))
        assertRenders(
            InfoSupportView(isPresented: .constant(true))
                .environmentObject(APIService.shared)
        )
        assertRenders(
            RulesSlideshowView(isPresented: .constant(true), registerActivity: {})
        )
    }

    func testInputAndStatusComponentsRenderTheirMainStates() {
        assertRenders(BrandBackground())
        assertRenders(LoadingOverlay(message: "Daten werden geladen"))
        assertRenders(
            ParticipantGenderView(isSubmitting: false, errorMessage: nil, onSelect: { _ in })
        )
        assertRenders(
            ParticipantGenderView(isSubmitting: true, errorMessage: "Bitte erneut versuchen", onSelect: { _ in })
        )
        assertRenders(
            CustomNumberKeyboard(
                text: .constant("42"),
                doneLabel: "Anmelden",
                placeholder: "PIN",
                maxDigits: 2,
                obscuresText: true,
                onDone: {}
            )
        )
    }

    func testParticipantSupportAndNavigationViewsRender() {
        let api = APIService.shared

        assertRenders(
            FeedbackView(isPresented: .constant(true))
                .environmentObject(api)
        )
        assertRenders(
            LoginScreensaverView(dismiss: {})
                .environmentObject(api)
        )
        assertRenders(
            HowToUseView(isPresented: .constant(true), registerActivity: {})
                .environmentObject(api)
        )
        assertRenders(
            SidebarView(
                secondsRemaining: 24,
                registerActivity: {},
                logout: {},
                showOverviewOverlay: .constant(false),
                selectedOverviewSection: .constant(.matches),
                showGuideOverlay: .constant(false),
                showRulesOverlay: .constant(false),
                showInfoOverlay: .constant(false)
            )
            .environmentObject(api)
        )
    }

    func testMatchInputRendersSelectionAndDeliveryStates() {
        assertRenders(
            MatchInputBox(
                targetNumber: .constant(""),
                showKeyboard: .constant(true),
                showTextKeyboard: .constant(false),
                selectedActions: .constant([]),
                matchMessage: .constant(""),
                quickMessages: ["Hallo"],
                onSend: {},
                targetIsConfirmed: false,
                fillsAvailableSpace: true,
                availableHeight: 768
            )
        )
        assertRenders(
            MatchInputBox(
                targetNumber: .constant("42"),
                showKeyboard: .constant(false),
                showTextKeyboard: .constant(false),
                selectedActions: .constant(Set(["normal", "bjob"])),
                matchMessage: .constant("Hallo"),
                quickMessages: ["Hallo", "Treffen wir uns?"],
                onSend: {},
                isSending: false,
                targetIsConfirmed: true,
                allowedActionTypes: Set(["bjob", "hjob", "ljob"]),
                usesOfflineSelectionFallback: true,
                queuedSendCount: 3,
                queuedBatchCount: 1,
                deliveryStatus: .partiallyDelivered(delivered: 1, queued: 2),
                canUndoLastActions: true,
                withdrawalConfirmationMessage: "Aktion zurückgezogen",
                fillsAvailableSpace: true,
                availableHeight: 768
            )
        )
        assertRenders(
            MatchInputBox(
                targetNumber: .constant("7"),
                showKeyboard: .constant(false),
                showTextKeyboard: .constant(false),
                selectedActions: .constant(Set(["hot"])),
                matchMessage: .constant(""),
                quickMessages: [],
                onSend: {},
                targetIsConfirmed: true,
                deliveryStatus: .failed,
                deliveryErrorMessage: "Senden fehlgeschlagen"
            )
        )
    }

    private func assertRenders<Content: View>(
        _ content: Content,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let renderer = ImageRenderer(
            content: content.frame(width: 1_024, height: 768)
        )
        renderer.scale = 1

        XCTAssertNotNil(renderer.uiImage, file: file, line: line)
    }
}
