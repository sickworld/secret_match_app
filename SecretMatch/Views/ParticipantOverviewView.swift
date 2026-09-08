import SwiftUI

enum ParticipantOverviewSection {
    case matches
    case interests
    case actions
}

struct ParticipantOverviewView: View {
    private struct OverviewEntry: Identifiable {
        let id: String
        let other: String
        let type: String
        let message: String?
    }

    @EnvironmentObject private var api: APIService
    @Environment(\.secretMatchHighContrast) private var highContrast
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Binding var isPresented: Bool
    @Binding var selectedSection: ParticipantOverviewSection
    @State private var matches: [Match] = []
    @State private var interests: [IncomingInterest] = []
    @State private var actions: [SecretAction] = []
    @State private var selectedType = "all"
    @State private var numberQuery = ""
    @State private var matchesLoadErrorMessage: String?
    @State private var interestsLoadErrorMessage: String?
    @State private var actionsLoadErrorMessage: String?
    @State private var isLoadingMatches = true
    @State private var isLoadingInterests = true
    @State private var isLoadingActions = true

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 18) {
                header
                sectionPicker
                filterBar
                content
            }
            .frame(maxWidth: 1_020, maxHeight: 780)
            .secretCard(cornerRadius: 26, padding: 28)
            .padding(24)
        }
        .task(id: isPresented) {
            guard isPresented else { return }
            await loadAllSections()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("DEINE ÜBERSICHT · \(filteredEntries.count)")
                    .font(.caption.bold())
                    .tracking(1.8)
                    .foregroundStyle(SecretMatchTheme.secondary)
                Text(sectionTitle)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(sectionSubtitle)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(SecretMatchTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button {
                isPresented = false
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
    }

    private var sectionPicker: some View {
        HStack(spacing: 10) {
            sectionButton(
                title: "Matches",
                explanation: "Gegenseitig",
                count: matches.count,
                systemImage: "sparkles",
                section: .matches,
                color: SecretMatchTheme.primary
            )
            sectionButton(
                title: "Interesse",
                explanation: "Wartet auf dich",
                count: interests.count,
                systemImage: "heart.text.square.fill",
                section: .interests,
                color: SecretMatchTheme.secondary,
                selectedForegroundColor: .black
            )
            sectionButton(
                title: "Aktionen",
                explanation: "An dich gesendet",
                count: actions.count,
                systemImage: "paperplane.fill",
                section: .actions,
                color: Color(hex: "#3E9ED6"),
                selectedForegroundColor: .black
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Bereich auswählen")
    }

    private func sectionButton(
        title: String,
        explanation: String,
        count: Int,
        systemImage: String,
        section: ParticipantOverviewSection,
        color: Color,
        selectedForegroundColor: Color = .white
    ) -> some View {
        let isSelected = selectedSection == section
        let usesColorIndependentSelection = highContrast || differentiateWithoutColor

        return Button {
            withAnimation(.easeOut(duration: 0.18)) {
                selectedSection = section
                selectedType = "all"
                numberQuery = ""
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .bold))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(title) · \(count)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text(explanation)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(
                            isSelected && usesColorIndependentSelection
                                ? Color.black.opacity(0.76)
                                : (isSelected ? selectedForegroundColor.opacity(0.82) : SecretMatchTheme.muted)
                        )
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .bold))
                    .frame(width: 22, height: 22)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(
                isSelected
                    ? (usesColorIndependentSelection ? Color.black : selectedForegroundColor)
                    : Color.white
            )
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity, minHeight: 66)
            .background(
                usesColorIndependentSelection
                    ? (isSelected ? Color.white : Color.black)
                    : (isSelected ? color.opacity(0.9) : color.opacity(0.14))
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        usesColorIndependentSelection ? Color.white : color.opacity(isSelected ? 1 : 0.5),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(explanation), \(count) Einträge")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var filterBar: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    filterButton(
                        "Alle \(activeEntries.count)",
                        type: "all",
                        color: SecretMatchTheme.secondary,
                        selectedForegroundColor: .black
                    )
                    if selectedSection == .actions {
                        filterButton("👄 Blow-Job \(count(for: "bjob"))", type: "bjob", color: Color(hex: "#3E9ED6"))
                        filterButton("✋ Hand-Job \(count(for: "hjob"))", type: "hjob", color: Color(hex: "#E6923E"))
                        filterButton("👅 Lick-Job \(count(for: "ljob"))", type: "ljob", color: Color(hex: "#D65C8D"))
                    } else {
                        filterButton("❤️ Hot \(count(for: "normal"))", type: "normal", color: Color(hex: "#E83E8C"))
                        filterButton("🍆 Fuck \(count(for: "hot"))", type: "hot", color: Color(hex: "#8E63D2"))
                    }
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "number")
                    .foregroundStyle(SecretMatchTheme.secondary)
                TextField("Nach Eventnummer filtern", text: $numberQuery)
                    .keyboardType(.numberPad)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                if !numberQuery.isEmpty {
                    Button {
                        numberQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(SecretMatchTheme.muted)
                    }
                    .accessibilityLabel("Nummernfilter löschen")
                }
            }
            .padding(.horizontal, 15)
            .frame(minHeight: 52)
            .background(SecretMatchTheme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(SecretMatchTheme.border))
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoadingActiveSection {
            ProgressView("\(sectionTitle) werden geladen…")
                .tint(SecretMatchTheme.secondary)
                .foregroundStyle(.white)
                .frame(maxHeight: .infinity)
        } else if let activeLoadErrorMessage {
            loadErrorState(message: activeLoadErrorMessage)
        } else if filteredEntries.isEmpty {
            ContentUnavailableView(
                emptyStateTitle,
                systemImage: emptyStateIcon,
                description: Text(emptyStateDescription)
            )
            .foregroundStyle(.white)
            .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 360), spacing: 14)], spacing: 14) {
                    ForEach(filteredEntries) { entry in
                        overviewCard(entry)
                    }
                }
                .padding(.vertical, 2)
            }
            .refreshable { await loadSelectedSection() }
        }
    }

    private func filterButton(
        _ title: String,
        type: String,
        color: Color,
        selectedForegroundColor: Color = .white
    ) -> some View {
        let isSelected = selectedType == type
        let usesColorIndependentSelection = highContrast || differentiateWithoutColor

        return Button {
            withAnimation(.easeOut(duration: 0.18)) {
                selectedType = type
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 19, height: 19)
                    .accessibilityHidden(true)
                Text(title)
            }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(
                    isSelected
                        ? (usesColorIndependentSelection ? Color.black : selectedForegroundColor)
                        : Color.white
                )
                .padding(.horizontal, 18)
                .frame(minHeight: 52)
                .background(
                    usesColorIndependentSelection
                        ? (isSelected ? Color.white : Color.black)
                        : (isSelected ? color.opacity(0.9) : color.opacity(0.14))
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(
                        usesColorIndependentSelection ? Color.white : color.opacity(isSelected ? 1 : 0.5),
                        lineWidth: isSelected ? 2 : 1
                    )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(isSelected ? "ausgewählt" : "nicht ausgewählt")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func overviewCard(_ entry: OverviewEntry) -> some View {
        let color = typeColor(for: entry.type)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 15) {
                Text(typeEmoji(for: entry.type))
                    .font(.system(size: 32))
                    .frame(width: 58, height: 58)
                    .background(color.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.other.displayEventNumber)
                        .font(.system(size: 40, weight: .heavy, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(.white)
                    if let entryExplanation {
                        Text(entryExplanation)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(SecretMatchTheme.muted)
                    }
                }

                Spacer()

                Text(typeTitle(for: entry.type))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(highContrast || differentiateWithoutColor ? Color.black : Color.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(highContrast || differentiateWithoutColor ? Color.white : color.opacity(0.72))
                    .clipShape(Capsule())
            }

            if let message = entry.message, !message.isEmpty {
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "quote.opening")
                        .foregroundStyle(color)
                    Text(message)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(13)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(18)
        .background(color.opacity(0.13))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(color.opacity(0.62), lineWidth: 1.2))
        .accessibilityElement(children: .combine)
    }

    private func loadErrorState(message: String) -> some View {
        ContentUnavailableView {
            Label("\(sectionTitle) konnten nicht geladen werden", systemImage: "wifi.exclamationmark")
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
            return matches.map { OverviewEntry(id: $0.id, other: $0.other, type: $0.type, message: $0.message) }
        case .interests:
            return interests.map { OverviewEntry(id: $0.id, other: $0.other, type: $0.type, message: $0.message) }
        case .actions:
            return actions.map {
                OverviewEntry(id: $0.id, other: $0.sender_number, type: $0.action_type, message: nil)
            }
        }
    }

    private var filteredEntries: [OverviewEntry] {
        let digits = numberQuery.filter(\.isNumber)
        return activeEntries.filter { entry in
            (selectedType == "all" || entry.type == selectedType)
                && (digits.isEmpty || entry.other.filter(\.isNumber).contains(digits))
        }
    }

    private func count(for type: String) -> Int {
        activeEntries.filter { $0.type == type }.count
    }

    private var isLoadingActiveSection: Bool {
        switch selectedSection {
        case .matches: return isLoadingMatches
        case .interests: return isLoadingInterests
        case .actions: return isLoadingActions
        }
    }

    private var activeLoadErrorMessage: String? {
        switch selectedSection {
        case .matches: return matchesLoadErrorMessage
        case .interests: return interestsLoadErrorMessage
        case .actions: return actionsLoadErrorMessage
        }
    }

    private var sectionTitle: String {
        switch selectedSection {
        case .matches: return "Matches"
        case .interests: return "Interesse an dir"
        case .actions: return "Erhaltene Aktionen"
        }
    }

    private var sectionSubtitle: String {
        switch selectedSection {
        case .matches: return "Ihr habt euch gegenseitig gewählt – hier ist der Kontakt bestätigt."
        case .interests: return "Diese Nummern haben dich gewählt. Du hast noch nicht zurückgematcht."
        case .actions: return "Direkte Vorschläge, die andere Eventnummern an dich gesendet haben."
        }
    }

    private var entryExplanation: String? {
        switch selectedSection {
        case .matches: return nil
        case .interests: return "Wartet auf deine Antwort"
        case .actions: return nil
        }
    }

    private var emptyStateTitle: String {
        if selectedType != "all" || !numberQuery.isEmpty {
            return "Keine passenden Einträge"
        }
        switch selectedSection {
        case .matches: return "Noch keine Matches"
        case .interests: return "Noch kein offenes Interesse"
        case .actions: return "Noch keine erhaltenen Aktionen"
        }
    }

    private var emptyStateDescription: String {
        if selectedType != "all" || !numberQuery.isEmpty {
            return "Ändere den Typ- oder Nummernfilter, um wieder mehr zu sehen."
        }
        switch selectedSection {
        case .matches: return "Sobald es gegenseitig passt, erscheint das Match hier."
        case .interests: return "Neue Wünsche an dich erscheinen hier und werden nach einem Match automatisch einsortiert."
        case .actions: return "Neue direkte Vorschläge an dich erscheinen automatisch in dieser Übersicht."
        }
    }

    private var emptyStateIcon: String {
        switch selectedSection {
        case .matches: return "sparkles"
        case .interests: return "heart.text.square"
        case .actions: return "paperplane"
        }
    }

    private func typeTitle(for type: String) -> String {
        switch type {
        case "normal": return "Hot"
        case "hot": return "Fuck"
        case "bjob": return "Blow-Job"
        case "hjob": return "Hand-Job"
        case "ljob": return "Lick-Job"
        default: return "Andere"
        }
    }

    private func typeEmoji(for type: String) -> String {
        switch type {
        case "normal": return "❤️"
        case "hot": return "🍆"
        case "bjob": return "👄"
        case "hjob": return "✋"
        case "ljob": return "👅"
        default: return "✨"
        }
    }

    private func typeColor(for type: String) -> Color {
        switch type {
        case "normal": return Color(hex: "#E83E8C")
        case "hot": return Color(hex: "#8E63D2")
        case "bjob": return Color(hex: "#3E9ED6")
        case "hjob": return Color(hex: "#E6923E")
        case "ljob": return Color(hex: "#D65C8D")
        default: return SecretMatchTheme.secondary
        }
    }

    @MainActor
    private func loadAllSections() async {
        await loadMatches()
        await loadInterests()
        await loadActions()
    }

    @MainActor
    private func loadSelectedSection() async {
        switch selectedSection {
        case .matches: await loadMatches()
        case .interests: await loadInterests()
        case .actions: await loadActions()
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

    @MainActor
    private func loadActions() async {
        isLoadingActions = true
        actionsLoadErrorMessage = nil
        defer { isLoadingActions = false }
        do {
            actions = try await api.loadActions().filter {
                $0.receiver_number.normalizedEventNumber == api.number.normalizedEventNumber
            }
        } catch {
            actionsLoadErrorMessage = "Bitte prüfe die Netzwerkverbindung und versuche es erneut."
        }
    }
}
