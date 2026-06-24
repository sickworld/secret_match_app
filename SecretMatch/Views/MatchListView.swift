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
                    .font(.system(size: 26, weight: .bold, design: .rounded))
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
                                    Text(typeTitle(for: type))
                                        .font(.headline)
                                        .foregroundStyle(SecretMatchTheme.muted)
                                        .padding(.leading)

                                    ForEach(groupedMatches[type] ?? []) { match in
                                        HStack {
                                            Text("\(match.other)")
                                                .foregroundStyle(.white)
                                                .fontWeight(.medium)

                                            Spacer()
                                        }
                                        .padding()
                                        .background(SecretMatchTheme.surfaceRaised)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SecretMatchTheme.border))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Button("Schließen") {
                    isPresented = false
                    dismiss()
                }
                .buttonStyle(SecretPrimaryButtonStyle())
                .padding(.top, 20)
            }
            .frame(maxWidth: 400)
            .secretCard(cornerRadius: 24, padding: 28)
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
}
