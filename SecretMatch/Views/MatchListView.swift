import SwiftUI

struct MatchListView: View {
    @EnvironmentObject var api: APIService
    @State private var matches: [Match] = []
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    @State private var selectedType = "all"
    @State private var loadErrorMessage: String?

    var groupedMatches: [String: [Match]] {
        Dictionary(grouping: matches, by: { $0.type })
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

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

                HStack(spacing: 10) {
                    matchFilterButton("Alle \(matches.count)", type: "all", color: SecretMatchTheme.secondary)
                    matchFilterButton("❤️ Hot \(normalCount)", type: "normal", color: Color(hex: "#E83E8C"))
                    matchFilterButton("🍆 Fuck \(hotCount)", type: "hot", color: Color(hex: "#8E63D2"))
                }

                if let loadErrorMessage {
                    loadErrorState(message: loadErrorMessage)
                } else if filteredMatches.isEmpty {
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

                                            Text(match.other.displayEventNumber)
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

    private func loadErrorState(message: String) -> some View {
        ContentUnavailableView {
            Label("Matches konnten nicht geladen werden", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Erneut versuchen") {
                Task { await loadMatches() }
            }
            .buttonStyle(SecretPrimaryButtonStyle(fullWidth: false))
        }
        .foregroundStyle(.white)
        .frame(maxHeight: .infinity)
    }

    private var filteredMatches: [Match] {
        matches.filter { selectedType == "all" || $0.type == selectedType }
    }

    private var normalCount: Int { matches.filter { $0.type == "normal" }.count }
    private var hotCount: Int { matches.filter { $0.type == "hot" }.count }

    private func matchFilterButton(_ title: String, type: String, color: Color) -> some View {
        let isSelected = selectedType == type

        return Button {
            withAnimation(.easeOut(duration: 0.18)) {
                selectedType = type
            }
        } label: {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(isSelected ? color.opacity(0.9) : color.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(color.opacity(isSelected ? 1 : 0.55), lineWidth: isSelected ? 2 : 1)
                )
                .shadow(color: isSelected ? color.opacity(0.28) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func loadMatches() async {
        loadErrorMessage = nil
        do {
            matches = try await api.loadMatches()
        } catch {
            loadErrorMessage = "Bitte prüfe die Netzwerkverbindung und versuche es erneut."
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
