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
        HStack(alignment: .top, spacing: 14) {

            Image(systemName: icon(for: match.type))
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(SecretMatchTheme.primary)
                .frame(width: 44, height: 44)
                .background(SecretMatchTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(prettyMatchType(match.type))
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("\(match.number_a) ↔ \(match.number_b)")
                    .foregroundStyle(SecretMatchTheme.muted)
                    .font(.subheadline)

                // Datum optional, bewusst weggelassen
                // Text(match.created_at)
                //     .font(.caption2)
                //     .foregroundColor(.white.opacity(0.4))
            }

            Spacer()
        }
        .padding()
        .background(SecretMatchTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SecretMatchTheme.border))
    }

    // MARK: - Mapping

    private func prettyMatchType(_ type: String) -> String {
        switch type {
        case "hot":
            return "Fuck-Match"
        case "normal":
            return "Hot-Match"
        default:
            return type.capitalized
        }
    }

    private func icon(for type: String) -> String {
        switch type {
        case "hot":
            return "flame.fill"
        case "normal":
            return "sparkles"
        default:
            return "circle.hexagongrid.fill"
        }
    }
}
