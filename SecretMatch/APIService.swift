import Foundation
import Combine
import SwiftUI

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    private init() {}

    @Published var isLoggedIn: Bool = false
    @Published var number: String = ""
    @Published var matches: [Match] = []

    private let baseURL = URL(string: "https://secret-match.de/wp-json/secretmatch/v1")!

    func login(number: String) async throws {
        let url = baseURL.appendingPathComponent("login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "secretmatch_number=\(number)".data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        self.isLoggedIn = true
        self.number = number
    }

    func submitMatch(targetNumber: String, type: String) async throws -> String {
        let url = baseURL.appendingPathComponent("match")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body = "target_number=\(targetNumber)&match_type=\(type)"
        request.httpBody = body.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(MatchResponse.self, from: data)
        return decoded.data
    }

    struct MatchResponse: Codable {
        let success: Bool
        let data: String
    }

    func logout() {
        self.isLoggedIn = false
        self.number = ""
        self.matches = []
    }
}
