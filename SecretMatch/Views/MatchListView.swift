import SwiftUI

struct MatchListView: View {
    @EnvironmentObject var api: APIService
    @State private var matches: [Match] = []
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    @State private var selectedType = "all"

    var groupedMatches: [String: [Match]] {
        Dictionary(grouping: matches, by: { $0.type })
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("DEINE CONNECTIONS · \(filteredMatches.count)")
                            .font(.caption.bold())
                            .tracking(1.8)
                            .foregroundStyle(SecretMatchTheme.secondary)
                        Text("Matches")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Diese Personen möchten dasselbe wie du.")
                            .foregroundStyle(SecretMatchTheme.muted)
                    }
                    Spacer()
                    closeButton
                }

                Picker("Match-Typ", selection: $selectedType) {
                    Text("Alle \(matches.count)").tag("all")
                    Text("❤️ Hot \(normalCount)").tag("normal")
                    Text("🍆 Fuck \(hotCount)").tag("hot")
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .frame(minHeight: 58)

                if filteredMatches.isEmpty {
                    ContentUnavailableView(
                        selectedType == "all" ? "Noch keine Matches" : "Keine Matches dieses Typs",
                        systemImage: "heart",
                        description: Text("Sobald es gegenseitig passt, erscheint das Match hier.")
                    )
                    .foregroundStyle(.white)
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 14)], spacing: 14) {
                            ForEach(filteredMatches) { match in
                                let type = match.type
                                        HStack(spacing: 18) {
                                            Text(typeEmoji(for: type))
                                                .font(.system(size: 36))
                                                .frame(width: 60, height: 60)
                                                .background(typeColor(for: type).opacity(0.2))
                                                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Du hast ein Match!")
                                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                                    .foregroundStyle(.white)

                                                Text(typeTitle(for: type))
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(SecretMatchTheme.muted)

                                                Text(displayDate(match.created_at))
                                                    .font(.caption.monospacedDigit())
                                                    .foregroundStyle(.white.opacity(0.5))
                                            }

                                            Spacer()

                                            Text("#\(match.other)")
                                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 15)
                                                .padding(.vertical, 11)
                                                .background(Color.black.opacity(0.24))
                                                .clipShape(Capsule())
                                        }
                                        .padding(18)
                                        .background(typeColor(for: type).opacity(0.14))
                                        .clipShape(RoundedRectangle(cornerRadius: 18))
                                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(typeColor(for: type).opacity(0.65), lineWidth: 1.2))
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .refreshable { await loadMatches() }
                }
            }
            .frame(maxWidth: 980, maxHeight: 760)
            .secretCard(cornerRadius: 26, padding: 28)
            .padding(24)
        }
        .onAppear {
            Task { await loadMatches() }
        }
    }

    private var closeButton: some View {
        Button {
            isPresented = false
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(SecretMatchTheme.surfaceRaised)
                .clipShape(Circle())
        }
    }

    private var filteredMatches: [Match] {
        matches.filter { selectedType == "all" || $0.type == selectedType }
    }

    private var normalCount: Int { matches.filter { $0.type == "normal" }.count }
    private var hotCount: Int { matches.filter { $0.type == "hot" }.count }

    @MainActor
    private func loadMatches() async {
        do {
            matches = try await api.loadMatches()
        } catch {
            matches = []
        }
    }

    func typeTitle(for type: String) -> String {
        switch type {
            case "hot": return "Fuck-Matches"
            case "normal": return "Hot-Matches"
            default: return "Andere"
        }
    }

    private func typeEmoji(for type: String) -> String {
        switch type {
        case "hot": return "🍆"
        case "normal": return "❤️"
        default: return "✨"
        }
    }

    private func typeColor(for type: String) -> Color {
        switch type {
        case "hot": return Color(hex: "#8E63D2")
        case "normal": return Color(hex: "#E83E8C")
        default: return SecretMatchTheme.secondary
        }
    }

    private func displayDate(_ value: String) -> String {
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = input.date(from: value) else { return value }
        let output = DateFormatter()
        output.locale = Locale(identifier: "de_DE")
        output.dateFormat = "dd.MM. · HH:mm"
        return output.string(from: date)
    }
}
