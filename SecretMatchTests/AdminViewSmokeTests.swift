import SwiftUI
import XCTest
@testable import SecretMatch

@MainActor
final class AdminViewSmokeTests: XCTestCase {
    func testAdminOverviewAndNavigationRender() {
        let api = APIService.shared

        assertRenders(
            AdminMainView()
                .environmentObject(api)
        )
        for section in AdminDashboardSection.allCases {
            assertRenders(
                AdminDashboardView(
                    showBillboard: .constant(false),
                    selectedSection: .constant(section)
                )
                .environment(\.adminDashboardSection, section)
                .environmentObject(api)
            )
        }
        assertRenders(
            AdminSidebarView(
                showBillboard: .constant(false),
                dashboardSection: .constant(.overview),
                logout: {}
            )
            .environmentObject(api)
        )
        assertRenders(
            AdminLoginView(isPresented: .constant(true))
                .environmentObject(api)
        )
    }

    func testAdminOperationalViewsRenderEmptyStates() {
        let api = APIService.shared

        assertRenders(AdminEventCheckView().environmentObject(api))
        assertRenders(AdminDeliveryDiagnosticsView().environmentObject(api))
        assertRenders(AdminNumberLookupView().environmentObject(api))
        assertRenders(AdminFeedbackView().environmentObject(api))
        assertRenders(AdminEventLogView().environmentObject(api))
        assertRenders(AdminStatisticsView().environmentObject(api))
        assertRenders(
            AdminLiveFeedView(isPresented: .constant(true), isEmbedded: true)
                .environmentObject(api)
        )
    }

    func testAdminContentManagementViewsRenderEmptyStates() {
        let api = APIService.shared

        assertRenders(AdminEventAnnouncementsView().environmentObject(api))
        assertRenders(AdminScreensaverMediaView().environmentObject(api))
        assertRenders(
            AdminActionListView(isPresented: .constant(true), isEmbedded: true)
                .environmentObject(api)
        )
        assertRenders(
            AdminActionCatalogView(isPresented: .constant(true))
                .environmentObject(api)
        )
        assertRenders(
            AdminMatchListView(isPresented: .constant(true), isEmbedded: true)
                .environmentObject(api)
        )
        assertRenders(
            AdminMatchRequestListView(isPresented: .constant(true), isEmbedded: true)
                .environmentObject(api)
        )
        assertRenders(
            AdminMatchCatalogView(isPresented: .constant(true))
                .environmentObject(api)
        )
        assertRenders(
            AdminBillboardView(isPresented: .constant(true))
                .environmentObject(api)
        )
    }

    func testParticipantMainAndOverviewViewsRender() {
        let api = APIService.shared

        assertRenders(MatchView().environmentObject(api))
        for section in [ParticipantOverviewSection.matches, .interests, .actions] {
            assertRenders(
                ParticipantOverviewView(isPresented: .constant(true), selectedSection: section)
                    .environmentObject(api)
            )
        }
    }

    func testAdminViewsRenderPopulatedStates() throws {
        let api = APIService.shared
        let previousDashboard = api.adminDashboard
        let previousStatistics = api.adminStatistics
        let previousActions = api.adminActions
        let previousMatches = api.adminMatches
        let previousRequests = api.adminMatchRequests
        let previousFeedback = api.adminFeedback
        let previousLog = api.adminEventLog
        let previousParticipants = api.adminParticipants
        let previousCredentials = api.adminCredentials
        let previousStandardCredential = api.adminStandardCredentialActive
        defer {
            api.adminDashboard = previousDashboard
            api.adminStatistics = previousStatistics
            api.adminActions = previousActions
            api.adminMatches = previousMatches
            api.adminMatchRequests = previousRequests
            api.adminFeedback = previousFeedback
            api.adminEventLog = previousLog
            api.adminParticipants = previousParticipants
            api.adminCredentials = previousCredentials
            api.adminStandardCredentialActive = previousStandardCredential
        }

        api.adminDashboard = makeAdminDashboardFixture()
        api.adminStatistics = AdminStatisticsResponse(
            current: makeAdminStatisticsFixture(),
            lastEvent: makeAdminStatisticsFixture(),
            archives: []
        )
        api.adminActions = [
            AdminAction(
                id: "action-1",
                sender_number: "7",
                receiver_number: "42",
                action_type: "bjob",
                created_at: "2026-09-13T20:00:00Z",
                action_name: "Blow-Job",
                action_emoji: "💋",
                action_color: "#FF3366",
                action_category: "job",
                action_direction: "outgoing"
            ),
        ]
        api.adminMatches = [
            AdminMatch(
                id: "match-1",
                number_a: "7",
                number_b: "42",
                type: "normal",
                created_at: "2026-09-13T20:00:00Z"
            ),
        ]
        api.adminMatchRequests = [
            AdminMatchRequest(
                id: "request-1",
                participantA: "7",
                participantB: "42",
                type: "normal",
                message: "Hallo",
                createdAt: "2026-09-13T20:00:00Z",
                isMatched: false
            ),
        ]
        api.adminFeedback = [
            try JSONDecoder().decode(
                AdminFeedback.self,
                from: Data(
                    #"{"id":"feedback-1","rating":"5","functionality_rating":4,"ease_of_use_rating":"5","design_rating":4,"created_at":"2026-09-13T20:00:00Z"}"#.utf8
                )
            ),
        ]
        api.adminEventLog = [
            makeAdminLogEntry(
                eventType: "interaction_delivered",
                context: ["kind": .string("match")]
            ),
        ]
        api.adminParticipants = AdminParticipants(
            allowed: ["7", "42"],
            active: [AdminActiveParticipant(number: "7", lastActivity: 123)],
            profiles: [AdminParticipantProfile(number: "7", gender: .female)],
            pins: ["7": "12"]
        )
        api.adminCredentials = [AdminCredential(id: "credential-1", name: "Eventleitung", createdAt: 123)]
        api.adminStandardCredentialActive = true

        for section in AdminDashboardSection.allCases {
            assertRenders(
                AdminDashboardView(
                    showBillboard: .constant(false),
                    selectedSection: .constant(section)
                )
                .environment(\.adminDashboardSection, section)
                .environmentObject(api)
            )
        }
        assertRenders(AdminStatisticsView().environmentObject(api))
        assertRenders(AdminFeedbackView().environmentObject(api))
        assertRenders(AdminEventLogView().environmentObject(api))
        assertRenders(
            AdminNumberLookupView(query: "7", initialOverview: makeAdminNumberOverviewFixture())
                .environmentObject(api)
        )
        assertRenders(
            AdminDeliveryDiagnosticsView(
                sourceNumber: "7",
                targetNumber: "42",
                diagnostics: makeDeliveryDiagnosticsFixtures(),
                hasSearched: true
            )
            .environmentObject(api)
        )
        assertRenders(
            AdminDeliveryDiagnosticsView(sourceNumber: "7", diagnostics: [], hasSearched: true)
                .environmentObject(api)
        )
        assertRenders(
            AdminLiveFeedView(isPresented: .constant(true), isEmbedded: true)
                .environmentObject(api)
        )
        assertRenders(
            AdminActionListView(isPresented: .constant(true), isEmbedded: true)
                .environmentObject(api)
        )
        assertRenders(
            AdminMatchListView(isPresented: .constant(true), isEmbedded: true)
                .environmentObject(api)
        )
        assertRenders(
            AdminMatchRequestListView(isPresented: .constant(true), isEmbedded: true)
                .environmentObject(api)
        )
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
