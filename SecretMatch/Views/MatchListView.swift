import SwiftUI

struct MatchListView: View {
    @EnvironmentObject var api: APIService
    @State private var matches: [Match] = []
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool

    var groupedMatches: [String: [Match]] {
        Dictionary(grouping: matches, by: { $0.type })
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("CONNECTIONS")
                    .font(.caption2.bold())
                    .tracking(2)
                    .foregroundStyle(SecretMatchTheme.secondary)

                Text("Deine Matches")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if matches.isEmpty {
                    Text("Noch keine Matches")
                        .foregroundStyle(SecretMatchTheme.muted)
                        .padding(.top, 30)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            ForEach(groupedMatches.keys.sorted(), id: \.self) { type in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 10) {
                                        Text(typeEmoji(for: type))
                                            .font(.title2)
                                        Text(typeTitle(for: type))
                                            .font(.title3.bold())
                                            .foregroundStyle(.white)
                                    }
                                    .padding(.leading, 4)

                                    ForEach(groupedMatches[type] ?? []) { match in
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
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }

                Button("Schließen") {
                    isPresented = false
                    dismiss()
                }
                .buttonStyle(SecretPrimaryButtonStyle())
                .padding(.top, 20)
            }
            .frame(maxWidth: 720, maxHeight: 680)
            .secretCard(cornerRadius: 24, padding: 32)
            .padding(28)
        }
        .onAppear {
            Task {
                do {
                    let fetched = try await api.loadMatches()
                    self.matches = fetched
                } catch {
                    print("❌ Fehler beim Laden der Matches: \(error.localizedDescription)")
                }
            }
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
}
