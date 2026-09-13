@testable import SecretMatch
import SwiftUI
import XCTest

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

    func testAdminEditorsAndTextKeyboardsRenderRepresentativeStates() {
        assertRenders(
            AdminRecordEditorView(
                title: "Match anlegen",
                firstNumberLabel: "Nummer A",
                secondNumberLabel: "Nummer B",
                typeOptions: [
                    AdminRecordTypeOption(value: "normal", title: "❤️ Hot-Match"),
                    AdminRecordTypeOption(value: "hot", title: "🍆 Fuck-Match"),
                ],
                onSave: { _, _, _ in }
            )
        )
        assertRenders(
            AdminRecordEditorView(
                title: "Match bearbeiten",
                firstNumberLabel: "Nummer A",
                secondNumberLabel: "Nummer B",
                typeOptions: [AdminRecordTypeOption(value: "normal", title: "❤️ Hot-Match")],
                initialFirstNumber: "7",
                initialSecondNumber: "7",
                initialType: "normal",
                onSave: { _, _, _ in }
            )
        )
        assertRenders(
            CustomTextKeyboard(
                text: .constant("Hallo Match & Play!"),
                title: "Event-Mitteilung",
                maxCharacters: 180,
                doneLabel: "Speichern",
                allowsNewlines: true,
                obscuresText: false,
                forcesUppercase: false
            )
        )
        assertRenders(
            CustomTextKeyboard(
                text: .constant("PASSWORT"),
                title: "Passwort",
                maxCharacters: 32,
                obscuresText: true,
                forcesUppercase: true
            )
            .environment(\.secretMatchHighContrast, true)
        )
        assertRenders(
            AdminKeyboardTextField(
                title: "Nummer",
                text: .constant("42"),
                keyboard: .number(maxDigits: 10)
            )
        )
        assertRenders(
            AdminKeyboardTextField(
                title: "Passwort",
                text: .constant("geheim"),
                keyboard: .text(maxCharacters: 64),
                isSecure: true
            )
        )
        assertRenders(
            AdminKeyboardTextEditor(
                title: "Dialogtext",
                text: .constant("Willkommen beim Event"),
                maxCharacters: 500,
                allowsNewlines: true
            )
        )
    }

    func testAccessibleContainerRendersStoredScaleAndContrastVariants() {
        let defaults = UserDefaults.standard
        let levelKey = "secretmatch.interface-scale-level"
        let contrastKey = "secretmatch.high-contrast-enabled"
        let previousLevel = defaults.object(forKey: levelKey)
        let previousContrast = defaults.object(forKey: contrastKey)
        defer {
            if let previousLevel {
                defaults.set(previousLevel, forKey: levelKey)
            } else {
                defaults.removeObject(forKey: levelKey)
            }
            if let previousContrast {
                defaults.set(previousContrast, forKey: contrastKey)
            } else {
                defaults.removeObject(forKey: contrastKey)
            }
        }

        for level in 0 ... 2 {
            defaults.set(level, forKey: levelKey)
            defaults.set(level == 2, forKey: contrastKey)
            assertRenders(
                AccessibleInterfaceContainer {
                    BrandBackground()
                }
            )
        }
    }

    private func assertRenders<Content: View>(
        _ content: Content,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for size in [CGSize(width: 1_024, height: 768), CGSize(width: 768, height: 1_024)] {
            let renderer = ImageRenderer(
                content: content.frame(width: size.width, height: size.height)
            )
            renderer.scale = 1

            XCTAssertNotNil(renderer.uiImage, file: file, line: line)
        }
    }
}
