import Foundation
import XCTest
@testable import SecretMatch

@MainActor
final class AdminReportExporterTests: XCTestCase {
    func testCSVExportContainsMetricsAndEscapesFields() throws {
        let url = try AdminReportExporter.csv(
            for: makeAdminStatisticsFixture(),
            eventName: "Coverage Event \(UUID().uuidString)"
        )
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }

        let data = try Data(contentsOf: url)
        let contents = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertTrue(data.starts(with: Data([0xEF, 0xBB, 0xBF])))
        XCTAssertTrue(contents.contains("\"Match&Play Eventbericht\""))
        XCTAssertTrue(contents.contains("\"Teilnehmende\";\"84\""))
        XCTAssertTrue(contents.contains("\"Sondertyp \"\"A\"\"; Test\";\"20\""))
        XCTAssertTrue(contents.contains("\"20:00\";\"0\";\"0\";\"1\""))
    }

    func testPDFExportCreatesAReadableMultiPageDocument() throws {
        let url = try AdminReportExporter.pdf(
            for: makeAdminStatisticsFixture(),
            eventName: "Coverage Event \(UUID().uuidString)"
        )
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }

        let data = try Data(contentsOf: url)

        XCTAssertTrue(data.starts(with: Data("%PDF".utf8)))
        XCTAssertGreaterThan(data.count, 5_000)
    }
}
