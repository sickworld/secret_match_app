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
                Text("Alle Matches")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                if api.adminMatches.isEmpty {
                    Text("Keine Matches gefunden")
                        .foregroundColor(.white.opacity(0.6))
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
                .buttonStyle(SidebarButtonStyle())
            }
            .padding()
            .frame(maxWidth: 520)
            .background(Color(hex: "#3c0d1f").opacity(0.95))
            .cornerRadius(24)
        }
        .task {
            await api.loadAdminMatches()
        }
    }

    // MARK: - Einzelnes Match

    @ViewBuilder
    private func matchRow(_ match: AdminMatch) -> some View {
        HStack(alignment: .top, spacing: 14) {

            Text(icon(for: match.type))
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 6) {
                Text(prettyMatchType(match.type))
                    .font(.headline)
                    .foregroundColor(.white)

                Text("\(match.number_a) ↔ \(match.number_b)")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.subheadline)

                // Datum optional, bewusst weggelassen
                // Text(match.created_at)
                //     .font(.caption2)
                //     .foregroundColor(.white.opacity(0.4))
            }

            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(14)
    }

    // MARK: - Mapping

    private func prettyMatchType(_ type: String) -> String {
        switch type {
        case "hot":
            return "Fuck-Match 🔥"
        case "normal":
            return "Hot-Match ❤️"
        default:
            return type.capitalized
        }
    }

    private func icon(for type: String) -> String {
        switch type {
        case "hot":
            return "🔥"
        case "normal":
            return "❤️"
        default:
            return "✨"
        }
    }
}
