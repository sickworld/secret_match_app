import SwiftUI

struct AdminLiveFeedView: View {
    @EnvironmentObject private var api: APIService
    @Binding var isPresented: Bool
    var isEmbedded = false
    @State private var isInitialLoading = true
    @State private var isRefreshing = false

    var body: some View {
        ZStack {
            if !isEmbedded {
                Color.black.opacity(0.68)
                    .ignoresSafeArea()
                    .onTapGesture { isPresented = false }
            }

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("EVENT CONTROL · LIVE")
                            .font(.caption.bold())
                            .tracking(1.8)
                            .foregroundStyle(SecretMatchTheme.secondary)
                        Text("Livefeed")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    if !isEmbedded {
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title3.bold())
                                .frame(width: 50, height: 50)
                                .foregroundStyle(.white)
                                .background(SecretMatchTheme.surfaceRaised)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Livefeed schließen")
                    }
                }

                HStack(spacing: 9) {
                    if isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.green)
                        Text("Livefeed wird aktualisiert …")
                    } else {
                        Image(systemName: "dot.radiowaves.left.and.right")
                        Text("Aktualisiert sich alle 10 Sekunden")
                    }
                }
                .font(.caption.bold())
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity, alignment: .leading)

                if isInitialLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .controlSize(.large)
                            .tint(SecretMatchTheme.secondary)
                        Text("Livefeed wird geladen …")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if entries.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Aktivität",
                        systemImage: "waveform.path",
                        description: Text("Neue Aktionen und Matches erscheinen automatisch hier.")
                    )
                    .foregroundStyle(.white)
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(entries) { entry in
                                row(entry)
                            }
                        }
                    }
                    .refreshable { await refresh() }
                }
            }
            .frame(maxWidth: isEmbedded ? 1040 : 680, maxHeight: isEmbedded ? .infinity : 780)
            .secretCard(cornerRadius: 26, padding: 22)
            .padding(16)
        }
        .task {
            await refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                await refresh()
            }
        }
    }

    private func row(_ entry: Entry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(entry.emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(entry.color.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title).font(.headline).foregroundStyle(.white)
                Text(entry.detail).font(.subheadline.weight(.semibold)).foregroundStyle(SecretMatchTheme.muted)
                Text(entry.createdAt).font(.caption2.monospacedDigit()).foregroundStyle(.white.opacity(0.48))
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(entry.color.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(entry.color.opacity(0.32)))
    }

    private var entries: [Entry] {
        let actions = api.adminActions.map { action in
            Entry(id: "action-\(action.id)", createdAt: action.created_at,
                  emoji: actionEmoji(action.action_type), title: actionTitle(action.action_type),
                  detail: "\(action.sender_number.displayEventNumber) → \(action.receiver_number.displayEventNumber)", color: actionColor(action.action_type))
        }
        let matches = api.adminMatches.map { match in
            let isHot = match.type == "hot" || match.type == "F-"
            return Entry(id: "match-\(match.id)", createdAt: match.created_at,
                         emoji: isHot ? "🍆" : "❤️",
                         title: isHot ? "Fuck-Match entstanden" : "Hot-Match entstanden",
                         detail: "\(match.number_a.displayEventNumber) ↔ \(match.number_b.displayEventNumber)",
                         color: isHot ? Color(hex: "#8E63D2") : Color(hex: "#E83E8C"))
        }
        return (actions + matches).sorted { $0.createdAt > $1.createdAt }
    }

    private func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer {
            isRefreshing = false
            isInitialLoading = false
        }
        try? await api.loadAdminActions()
        try? await api.loadAdminMatches()
    }

    private func actionEmoji(_ type: String) -> String {
        ["normal": "❤️", "hot": "🍆", "bjob": "👄", "hjob": "✋", "ljob": "👅"][type] ?? "💌"
    }

    private func actionTitle(_ type: String) -> String {
        ["normal": "Hot-Aktion gesendet", "hot": "Fuck-Aktion gesendet", "bjob": "Blow-Job-Aktion gesendet",
         "hjob": "Hand-Job-Aktion gesendet", "ljob": "Lick-Job-Aktion gesendet"][type] ?? "Aktion gesendet"
    }

    private func actionColor(_ type: String) -> Color {
        switch type {
        case "normal": return Color(hex: "#E83E8C")
        case "hot": return Color(hex: "#8E63D2")
        case "bjob": return Color(hex: "#3E9ED6")
        case "hjob": return Color(hex: "#E6923E")
        case "ljob": return Color(hex: "#D65C8D")
        default: return SecretMatchTheme.primary
        }
    }
}

private struct Entry: Identifiable {
    let id: String
    let createdAt: String
    let emoji: String
    let title: String
    let detail: String
    let color: Color
}
