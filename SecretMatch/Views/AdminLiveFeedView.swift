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
                                .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
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
            .secretCard(padding: 22)
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
                .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title).font(.headline).foregroundStyle(.white)
                Text(entry.detail).font(.subheadline.weight(.semibold)).foregroundStyle(SecretMatchTheme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(entry.color.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius).stroke(entry.color.opacity(0.32)))
    }

    private var entries: [Entry] {
        let actions = api.adminActions.map { action in
            Entry(id: "action-\(action.id)", createdAt: action.created_at,
                  emoji: actionEmoji(action), title: actionTitle(action),
                  detail: "\(action.sender_number.displayEventNumber) → \(action.receiver_number.displayEventNumber)", color: actionColor(action))
        }
        let matches = api.adminMatches.map { match in
            let definition = api.matchDefinitions.first(where: { $0.id == MatchDefinition.normalizedID(match.type) }) ?? .fallback(for: match.type)
            return Entry(id: "match-\(match.id)", createdAt: match.created_at,
                         emoji: definition.emoji,
                         title: "\(definition.name) entstanden",
                         detail: "\(match.number_a.displayEventNumber) ↔ \(match.number_b.displayEventNumber)",
                         color: Color(hex: definition.color))
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
        try? await api.loadAdminMatchDefinitions()
        try? await api.loadAdminActions()
        try? await api.loadAdminMatches()
    }

    private func actionEmoji(_ action: AdminAction) -> String {
        action.action_emoji ?? api.actionDefinitions.first { $0.id == action.action_type }?.emoji ?? ActionDefinition.fallback(for: action.action_type).emoji
    }

    private func actionTitle(_ action: AdminAction) -> String {
        let name = action.action_name ?? api.actionDefinitions.first { $0.id == action.action_type }?.name ?? ActionDefinition.fallback(for: action.action_type).name
        return "\(name)-Aktion gesendet"
    }

    private func actionColor(_ action: AdminAction) -> Color {
        Color(hex: action.action_color ?? api.actionDefinitions.first { $0.id == action.action_type }?.color ?? ActionDefinition.fallback(for: action.action_type).color)
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
