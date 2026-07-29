import SwiftUI

struct AdminMatchListView: View {
    @EnvironmentObject var api: APIService
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 20) {
                Text("EVENT CONTROL")
                    .font(.caption2.bold())
                    .tracking(2)
                    .foregroundStyle(SecretMatchTheme.secondary)

                Text("Alle Matches")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if api.adminMatches.isEmpty {
                    Text("Keine Matches gefunden")
                        .foregroundStyle(SecretMatchTheme.muted)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(api.adminMatches) { match in
                                matchRow(match)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Button("Schließen") {
                    isPresented = false
                }
                .buttonStyle(SecretPrimaryButtonStyle())
            }
            .frame(maxWidth: 520)
            .secretCard(cornerRadius: 24, padding: 28)
        }
        .task {
            await api.loadAdminMatches()
        }
    }

    // MARK: - Einzelnes Match

    @ViewBuilder
    private func matchRow(_ match: AdminMatch) -> some View {
        let color = matchColor(for: match.type)

        HStack(alignment: .top, spacing: 14) {
            Text(matchEmoji(for: match.type))
                .font(.system(size: 30))
                .frame(width: 54, height: 54)
                .background(color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(prettyMatchType(match.type))
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(match.number_a) ↔ \(match.number_b)")
                    .foregroundStyle(SecretMatchTheme.muted)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))

                // Datum optional, bewusst weggelassen
                // Text(match.created_at)
                //     .font(.caption2)
                //     .foregroundColor(.white.opacity(0.4))
            }

            Spacer()
        }
        .padding()
        .background(color.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.65), lineWidth: 1.2))
    }

    // MARK: - Mapping

    private func prettyMatchType(_ type: String) -> String {
        switch type {
        case "hot", "F-":
            return "Fuck-Match"
        case "normal":
            return "Hot-Match"
        default:
            return type.capitalized
        }
    }

    private func matchEmoji(for type: String) -> String {
        switch type {
        case "hot", "F-": return "🍆"
        case "normal": return "❤️"
        default: return "✨"
        }
    }

    private func matchColor(for type: String) -> Color {
        switch type {
        case "hot", "F-": return Color(hex: "#8E63D2")
        case "normal": return Color(hex: "#E83E8C")
        default: return SecretMatchTheme.secondary
        }
    }
}
