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
        let requestID: String?
        let isSent: Bool
    }

    @EnvironmentObject private var api: APIService
    @Environment(\.secretMatchHighContrast) private var highContrast
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Binding var isPresented: Bool
    let selectedSection: ParticipantOverviewSection
    @State private var matches: [Match] = []
    @State private var interests: [IncomingInterest] = []
    @State private var actions: [SecretAction] = []
    @State private var selectedType = "all"
    @State private var numberQuery = ""
    @State private var showsSentActions = false
    @State private var pendingWithdrawal: OverviewEntry?
    @State private var withdrawalErrorMessage: String?
    @State private var withdrawingRequestID: String?
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
                filterBar
                content
            }
            .frame(maxWidth: 1_020, maxHeight: 780)
            .secretCard(padding: 28)
            .padding(24)
        }
        .task(id: isPresented) {
            guard isPresented else { return }
            await loadSelectedSection()
        }
        .confirmationDialog(
            "Aktion zurückziehen?",
            isPresented: Binding(
                get: { pendingWithdrawal != nil },
                set: { if !$0 { pendingWithdrawal = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Aktion zurückziehen", role: .destructive) {
                guard let entry = pendingWithdrawal else { return }
                pendingWithdrawal = nil
                Task { await withdraw(entry) }
            }
            Button("Abbrechen", role: .cancel) { pendingWithdrawal = nil }
        } message: {
            Text("Die Aktion an \(pendingWithdrawal?.other.displayEventNumber ?? "dieser Nummer") wird beim Empfänger entfernt.")
        }
        .alert("Das hat nicht geklappt", isPresented: Binding(
            get: { withdrawalErrorMessage != nil },
            set: { if !$0 { withdrawalErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { withdrawalErrorMessage = nil }
        } message: {
            Text(withdrawalErrorMessage ?? "Bitte versuche es erneut.")
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
                    .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
            }
            .accessibilityLabel("Übersicht schließen")
        }
    }

    private var filterBar: some View {
        VStack(spacing: 12) {
            if selectedSection == .actions {
                HStack(spacing: 0) {
                    actionDirectionButton("Erhalten", sent: false, icon: "tray.and.arrow.down.fill")
                    actionDirectionButton("Von dir gesendet", sent: true, icon: "paperplane.fill")
                }
                .overlay(Rectangle().stroke(SecretMatchTheme.border, lineWidth: 1))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    filterButton(
                        "Alle \(activeEntries.count)",
                        type: "all",
                        color: SecretMatchTheme.secondary,
                        selectedForegroundColor: .black
                    )
                    if selectedSection == .actions {
                        ForEach(actionFilterDefinitions) { definition in
                            filterButton("\(definition.displayTitle) \(count(for: definition.id))", type: definition.id, color: Color(hex: definition.color))
                        }
                    } else {
                        ForEach(matchFilterDefinitions) { definition in
                            filterButton("\(definition.displayTitle) \(count(for: definition.id))", type: definition.id, color: Color(hex: definition.color))
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "number")
                    .foregroundStyle(SecretMatchTheme.secondary)
                AdminKeyboardTextField(
                    title: "Nach Eventnummer filtern",
                    text: $numberQuery,
                    keyboard: .number(maxDigits: 10),
                    keyboardTitle: "Übersicht nach Eventnummer filtern"
                )
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
            .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius).stroke(SecretMatchTheme.border))
        }
    }

    private func actionDirectionButton(_ title: String, sent: Bool, icon: String) -> some View {
        let isSelected = showsSentActions == sent
        return Button {
            withAnimation(.easeOut(duration: 0.18)) {
                showsSentActions = sent
                selectedType = "all"
                numberQuery = ""
            }
        } label: {
            Label(title, systemImage: icon)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? Color.black : Color.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(isSelected ? SecretMatchTheme.secondary : SecretMatchTheme.surfaceRaised)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                    .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous))

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
                .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous))
            }

            if selectedSection == .actions, entry.isSent, let requestID = entry.requestID {
                Button {
                    pendingWithdrawal = entry
                } label: {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                        Text(withdrawingRequestID == requestID ? "Wird zurückgezogen…" : "Aktion zurückziehen")
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.red.opacity(highContrast ? 1 : 0.72))
                    .overlay(Rectangle().stroke(Color.white.opacity(0.7), lineWidth: highContrast ? 2 : 1))
                }
                .buttonStyle(.plain)
                .disabled(withdrawingRequestID != nil)
            }
        }
        .padding(18)
        .background(color.opacity(0.13))
        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius).stroke(color.opacity(0.62), lineWidth: 1.2))
        .accessibilityElement(children: .contain)
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
            return matches.map { OverviewEntry(id: $0.id, other: $0.other, type: $0.type, message: $0.message, requestID: nil, isSent: false) }
        case .interests:
            return interests.map { OverviewEntry(id: $0.id, other: $0.other, type: $0.type, message: $0.message, requestID: nil, isSent: false) }
        case .actions:
            let ownNumber = api.number.normalizedEventNumber
            return actions.compactMap {
                let isSent = $0.sender_number.normalizedEventNumber == ownNumber
                guard isSent == showsSentActions else { return nil }
                return OverviewEntry(
                    id: $0.id,
                    other: isSent ? $0.receiver_number : $0.sender_number,
                    type: $0.action_type,
                    message: nil,
                    requestID: $0.request_id,
                    isSent: isSent
                )
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

    private var actionFilterDefinitions: [ActionDefinition] {
        let presentTypes = Set(activeEntries.map(\.type))
        return presentTypes.map(actionDefinition(for:))
            .sorted { $0.sortOrder == $1.sortOrder ? $0.name < $1.name : $0.sortOrder < $1.sortOrder }
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
        case .actions: return showsSentActions ? "Von dir gesendet" : "Erhaltene Aktionen"
        }
    }

    private var sectionSubtitle: String {
        switch selectedSection {
        case .matches: return "Ihr habt euch gegenseitig gewählt – hier ist der Kontakt bestätigt."
        case .interests: return "Diese Nummern haben dich gewählt. Du hast noch nicht zurückgematcht."
        case .actions:
            return showsSentActions
                ? "Hier kannst du eine versehentlich gesendete Aktion zurückziehen."
                : "Direkte Vorschläge, die andere Eventnummern an dich gesendet haben."
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
        case .actions: return showsSentActions ? "Noch keine gesendeten Aktionen" : "Noch keine erhaltenen Aktionen"
        }
    }

    private var emptyStateDescription: String {
        if selectedType != "all" || !numberQuery.isEmpty {
            return "Ändere den Typ- oder Nummernfilter, um wieder mehr zu sehen."
        }
        switch selectedSection {
        case .matches: return "Sobald es gegenseitig passt, erscheint das Match hier."
        case .interests: return "Neue Wünsche an dich erscheinen hier und werden nach einem Match automatisch einsortiert."
        case .actions:
            return showsSentActions
                ? "Deine gesendeten Aktionen erscheinen hier und können bei Bedarf zurückgezogen werden."
                : "Neue direkte Vorschläge an dich erscheinen automatisch in dieser Übersicht."
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
        selectedSection == .actions
            ? actionDefinition(for: type).name
            : matchDefinition(for: type).name
    }

    private func typeEmoji(for type: String) -> String {
        selectedSection == .actions ? actionDefinition(for: type).emoji : matchDefinition(for: type).emoji
    }

    private func typeColor(for type: String) -> Color {
        selectedSection == .actions ? Color(hex: actionDefinition(for: type).color) : Color(hex: matchDefinition(for: type).color)
    }

    private var matchFilterDefinitions: [MatchDefinition] {
        let used = Set(activeEntries.map(\.type).map(MatchDefinition.normalizedID))
        var values = api.matchDefinitions.filter { $0.enabled || used.contains($0.id) }
        for id in used where !values.contains(where: { $0.id == id }) { values.append(.fallback(for: id)) }
        return values.sorted { $0.sortOrder < $1.sortOrder }
    }

    private func matchDefinition(for type: String) -> MatchDefinition {
        let id = MatchDefinition.normalizedID(type)
        return api.matchDefinitions.first(where: { $0.id == id }) ?? .fallback(for: id)
    }

    private func actionDefinition(for type: String) -> ActionDefinition {
        if let definition = api.actionDefinitions.first(where: { $0.id == type }) {
            return definition
        }
        if let action = actions.first(where: { $0.action_type == type }),
           let name = action.action_name,
           let color = action.action_color {
            return ActionDefinition(
                id: type,
                name: name,
                emoji: action.action_emoji ?? "✨",
                color: color,
                category: action.action_category ?? "play",
                direction: action.action_direction ?? "neutral",
                targetGender: "any",
                enabled: false,
                sortOrder: 999
            )
        }
        return ActionDefinition.fallback(for: type)
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
            actions = try await api.loadActions()
        } catch {
            actionsLoadErrorMessage = "Bitte prüfe die Netzwerkverbindung und versuche es erneut."
        }
    }

    @MainActor
    private func withdraw(_ entry: OverviewEntry) async {
        guard let requestID = entry.requestID else { return }
        withdrawingRequestID = requestID
        defer { withdrawingRequestID = nil }
        do {
            try await api.withdrawAction(requestID: requestID)
            actions.removeAll { $0.request_id == requestID }
        } catch {
            withdrawalErrorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Die Aktion konnte gerade nicht zurückgezogen werden. Bitte versuche es erneut."
        }
    }
}
