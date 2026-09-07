import SwiftUI

enum MatchOverviewSection {
    case matches
    case interests
}

struct MatchListView: View {
    private struct OverviewEntry: Identifiable {
        let id: String
        let other: String
        let type: String
        let message: String?
    }

    @EnvironmentObject var api: APIService
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    @State private var matches: [Match] = []
    @State private var interests: [IncomingInterest] = []
    @State private var selectedSection: MatchOverviewSection
    @State private var selectedType = "all"
    @State private var matchesLoadErrorMessage: String?
    @State private var interestsLoadErrorMessage: String?
    @State private var isLoadingMatches = true
    @State private var isLoadingInterests = true

    init(isPresented: Binding<Bool>, initialSection: MatchOverviewSection = .matches) {
        _isPresented = isPresented
        _selectedSection = State(initialValue: initialSection)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(sectionEyebrow)
                            .font(.caption.bold())
                            .tracking(1.8)
                            .foregroundStyle(SecretMatchTheme.secondary)
                        Text(sectionTitle)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(sectionSubtitle)
                            .foregroundStyle(SecretMatchTheme.muted)
                    }
                    Spacer()
                    closeButton
                }

                HStack(spacing: 10) {
                    overviewButton(
                        "Matches \(matches.count)",
                        systemImage: "sparkles",
                        section: .matches,
                        color: SecretMatchTheme.primary
                    )
                    overviewButton(
                        "Interesse an dir \(interests.count)",
                        systemImage: "heart.text.square.fill",
                        section: .interests,
                        color: SecretMatchTheme.secondary
                    )
                }

                HStack(spacing: 10) {
                    matchFilterButton("Alle \(activeEntries.count)", type: "all", color: SecretMatchTheme.secondary)
                    matchFilterButton("❤️ Hot \(normalCount)", type: "normal", color: Color(hex: "#E83E8C"))
                    matchFilterButton("🍆 Fuck \(hotCount)", type: "hot", color: Color(hex: "#8E63D2"))
                }

                if isLoadingActiveSection {
                    ProgressView(selectedSection == .matches ? "Matches werden geladen…" : "Interessen werden geladen…")
                        .tint(SecretMatchTheme.secondary)
                        .foregroundStyle(.white)
                        .frame(maxHeight: .infinity)
                } else if let activeLoadErrorMessage {
                    loadErrorState(message: activeLoadErrorMessage)
                } else if filteredEntries.isEmpty {
                    ContentUnavailableView(
                        emptyStateTitle,
                        systemImage: selectedSection == .matches ? "heart" : "heart.text.square",
                        description: Text(emptyStateDescription)
                    )
                    .foregroundStyle(.white)
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 14)], spacing: 14) {
                            ForEach(filteredEntries) { entry in
                                connectionRow(entry)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .refreshable { await loadSelectedSection() }
                }
            }
            .frame(maxWidth: 980, maxHeight: 760)
            .secretCard(cornerRadius: 26, padding: 28)
            .padding(24)
        }
        .task(id: isPresented) {
            guard isPresented else { return }
            await loadMatches()
            await loadInterests()
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
        .accessibilityLabel("Übersicht schließen")
    }

    private func overviewButton(
        _ title: String,
        systemImage: String,
        section: MatchOverviewSection,
        color: Color
    ) -> some View {
        let isSelected = selectedSection == section

        return Button {
            withAnimation(.easeOut(duration: 0.18)) {
                selectedSection = section
                selectedType = "all"
            }
        } label: {
            Label(title, systemImage: systemImage)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(isSelected ? color.opacity(0.9) : color.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(color.opacity(isSelected ? 1 : 0.55), lineWidth: isSelected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func loadErrorState(message: String) -> some View {
        ContentUnavailableView {
            Label(
                selectedSection == .matches
                    ? "Matches konnten nicht geladen werden"
                    : "Interessen konnten nicht geladen werden",
                systemImage: "wifi.exclamationmark"
            )
        } description: {
            Text(message)
        } actions: {
            Button("Erneut versuchen") {
                Task { await loadSelectedSection() }
            }
            .buttonStyle(SecretPrimaryButtonStyle(fullWidth: false))
        }
        .foregroundStyle(.white)
        .frame(maxHeight: .infinity)
    }

    private var activeEntries: [OverviewEntry] {
        switch selectedSection {
        case .matches:
            return matches.map {
                OverviewEntry(id: $0.id, other: $0.other, type: $0.type, message: $0.message)
            }
        case .interests:
            return interests.map {
                OverviewEntry(id: $0.id, other: $0.other, type: $0.type, message: $0.message)
            }
        }
    }

    private var filteredEntries: [OverviewEntry] {
        activeEntries.filter { selectedType == "all" || $0.type == selectedType }
    }

    private var normalCount: Int { activeEntries.filter { $0.type == "normal" }.count }
    private var hotCount: Int { activeEntries.filter { $0.type == "hot" }.count }

    private var isLoadingActiveSection: Bool {
        selectedSection == .matches ? isLoadingMatches : isLoadingInterests
    }

    private var activeLoadErrorMessage: String? {
        selectedSection == .matches ? matchesLoadErrorMessage : interestsLoadErrorMessage
    }

    private var sectionEyebrow: String {
        switch selectedSection {
        case .matches: return "DEINE CONNECTIONS · \(filteredEntries.count)"
        case .interests: return "OFFENE INTERESSEN · \(filteredEntries.count)"
        }
    }

    private var sectionTitle: String {
        selectedSection == .matches ? "Matches" : "Interesse an dir"
    }

    private var sectionSubtitle: String {
        switch selectedSection {
        case .matches: return "Diese Personen möchten dasselbe wie du."
        case .interests: return "Diese Personen haben dich gewählt – du sie aber noch nicht."
        }
    }

    private var emptyStateTitle: String {
        if selectedType != "all" {
            return selectedSection == .matches ? "Keine Matches dieses Typs" : "Keine Interessen dieses Typs"
        }
        return selectedSection == .matches ? "Noch keine Matches" : "Noch keine offenen Interessen"
    }

    private var emptyStateDescription: String {
        switch selectedSection {
        case .matches:
            return "Sobald es gegenseitig passt, erscheint das Match hier."
        case .interests:
            return "Neue Wünsche an dich erscheinen hier und werden bei einem Match automatisch einsortiert."
        }
    }

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

    private func connectionRow(_ entry: OverviewEntry) -> some View {
        let color = typeColor(for: entry.type)

        return HStack(spacing: 18) {
            Text(typeEmoji(for: entry.type))
                .font(.system(size: 36))
                .frame(width: 60, height: 60)
                .background(color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(selectedSection == .matches ? "Du hast ein Match!" : "Diese Person hat Interesse an dir")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(typeTitle(for: entry.type))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(SecretMatchTheme.muted)

                if let message = entry.message, !message.isEmpty {
                    Text("„\(message)“")
                        .font(.system(size: 19, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            Text(entry.other.displayEventNumber)
                .font(.system(size: 38, weight: .heavy, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(.white)
                .padding(.horizontal, 15)
                .padding(.vertical, 11)
                .background(Color.black.opacity(0.24))
                .clipShape(Capsule())
        }
        .padding(18)
        .background(color.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(color.opacity(0.65), lineWidth: 1.2))
    }

    @MainActor
    private func loadSelectedSection() async {
        switch selectedSection {
        case .matches: await loadMatches()
        case .interests: await loadInterests()
        }
    }

    @MainActor
    private func loadMatches() async {
        isLoadingMatches = true
        matchesLoadErrorMessage = nil
        defer { isLoadingMatches = false }

        do {
            matches = try await api.loadMatches()
        } catch {
            matchesLoadErrorMessage = "Bitte prüfe die Netzwerkverbindung und versuche es erneut."
        }
    }

    @MainActor
    private func loadInterests() async {
        isLoadingInterests = true
        interestsLoadErrorMessage = nil
        defer { isLoadingInterests = false }

        do {
            interests = try await api.loadIncomingInterests()
        } catch {
            interestsLoadErrorMessage = "Bitte prüfe die Netzwerkverbindung und versuche es erneut."
        }
    }

    private func typeTitle(for type: String) -> String {
        switch type {
        case "hot": return selectedSection == .matches ? "Fuck-Match" : "Fuck-Interesse"
        case "normal": return selectedSection == .matches ? "Hot-Match" : "Hot-Interesse"
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
