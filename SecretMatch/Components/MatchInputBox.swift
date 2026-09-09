import SwiftUI

private struct ActionOption: Identifiable {
    let type: String
    let title: String
    let emoji: String
    let color: Color

    var id: String { type }
}

struct MatchInputBox: View {
    @Environment(\.secretMatchInterfaceScale) private var interfaceScale
    @Environment(\.secretMatchHighContrast) private var highContrast
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @State private var replacedCustomMessage: String?
    @State private var undoMessageTask: Task<Void, Never>?
    @State private var hidesDeliveredFeedback = false
    @Binding var targetNumber: String
    @Binding var showKeyboard: Bool
    @Binding var showTextKeyboard: Bool
    @Binding var selectedActions: Set<String>
    @Binding var matchMessage: String
    let quickMessages: [String]
    let onSend: () -> Void
    var targetIsConfirmed = false
    var allowedActionTypes: Set<String> = ["bjob", "hjob", "ljob"]
    var usesProfileBasedSelection = false
    var onEditTarget: () -> Void = {}
    var queuedSendCount = 0
    var queuedBatchCount = 0
    var isRetryingQueuedSends = false
    var deliveryStatus: InteractionDeliveryStatus?
    var deliveryErrorMessage: String?
    var onRetryQueuedSends: () -> Void = {}
    var canUndoLastActions = false
    var isUndoingLastActions = false
    var withdrawalConfirmationMessage: String?
    var onUndoLastActions: () -> Void = {}
    var fillsAvailableSpace = false
    var availableHeight: CGFloat?

    private let options = [
        ActionOption(type: "normal", title: "Hot Match", emoji: "❤️", color: Color(hex: "#E83E8C")),
        ActionOption(type: "hot", title: "Fuck Match", emoji: "🍆", color: Color(hex: "#8E63D2")),
        ActionOption(type: "bjob", title: "Blow-Job", emoji: "👄", color: Color(hex: "#3E9ED6")),
        ActionOption(type: "hjob", title: "Hand-Job", emoji: "✋", color: Color(hex: "#E6923E")),
        ActionOption(type: "ljob", title: "Lick-Job", emoji: "👅", color: Color(hex: "#D65C8D"))
    ]

    private var matchOptions: [ActionOption] {
        options.filter { $0.type == "normal" || $0.type == "hot" }
    }

    private var actionOptions: [ActionOption] {
        options.filter {
            $0.type != "normal" && $0.type != "hot" && allowedActionTypes.contains($0.type)
        }
    }

    private var actionColumns: [GridItem] {
        Array(repeating: GridItem(.flexible()), count: max(1, actionOptions.count))
    }

    private var normalizedScale: CGFloat {
        fillsAvailableSpace ? max(interfaceScale, 1) : 1
    }

    private var zoomProgress: CGFloat {
        min(max((normalizedScale - 1) / 0.30, 0), 1)
    }

    private func metric(_ standard: CGFloat, _ extraLarge: CGFloat) -> CGFloat {
        let renderedValue = standard + (extraLarge - standard) * zoomProgress
        return renderedValue / normalizedScale
    }

    private var visibleDeliveryStatus: InteractionDeliveryStatus? {
        guard let deliveryStatus else { return nil }

        if hidesDeliveredFeedback, case .delivered = deliveryStatus {
            return nil
        }

        return deliveryStatus
    }

    private var floatingDeliveryStatus: InteractionDeliveryStatus? {
        guard let status = visibleDeliveryStatus else { return nil }

        if queuedSendCount > 0 {
            switch status {
            case .queued, .partiallyDelivered:
                return nil
            default:
                break
            }
        }

        return status
    }

    private var floatingFeedbackBottomInset: CGFloat {
        fillsAvailableSpace ? metric(168, 145) : 124
    }

    private var content: some View {
        VStack(spacing: 0) {
            introHeader

            Color.clear
                .frame(height: fillsAvailableSpace ? metric(18, 16) : 22)

            if targetIsConfirmed {
                actionPanel
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                targetSelectionPanel
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .frame(
            maxWidth: fillsAvailableSpace ? .infinity : 780,
            alignment: .top
        )
    }

    private var introHeader: some View {
        VStack(spacing: 5) {
            Text("MAKE A MOVE")
                .font(.caption2.bold())
                .tracking(2)
                .foregroundStyle(SecretMatchTheme.secondary)

            Text(targetIsConfirmed ? "Was möchtest du senden?" : "An wen möchtest du senden?")
                .font(.system(size: metric(32, 37), weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(
                targetIsConfirmed
                    ? "Wähle jetzt Match-Wünsche oder passende Aktionen."
                    : "Gib zuerst die Zielnummer ein und bestätige sie auf der Tastatur."
            )
                .font(.system(size: metric(16, 18), weight: .medium, design: .rounded))
                .foregroundStyle(SecretMatchTheme.muted)
                .multilineTextAlignment(.center)
        }
    }

    private var targetSelectionPanel: some View {
        targetNumberSection
            .padding(.horizontal, metric(16, 17))
            .padding(.vertical, metric(16, 17))
            .background(SecretMatchTheme.surfaceRaised.opacity(highContrast ? 0.78 : 0.38))
            .overlay(Rectangle().stroke(SecretMatchTheme.border, lineWidth: highContrast ? 2 : 1))
    }

    private var actionPanel: some View {
        VStack(spacing: 0) {
            confirmedTargetSection
                .padding(.horizontal, metric(16, 17))
                .padding(.vertical, metric(12, 13))

            panelDivider

            VStack(alignment: .leading, spacing: metric(9, 9)) {
                panelSectionTitle("MATCH-WÜNSCHE")

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: metric(9, 10)
                ) {
                    ForEach(matchOptions) { option in
                        selectionButton(for: option)
                    }
                }

                Rectangle()
                    .fill(SecretMatchTheme.border.opacity(highContrast ? 1 : 0.75))
                    .frame(height: highContrast ? 2 : 1)
                    .padding(.vertical, metric(3, 3))
                    .accessibilityHidden(true)

                panelSectionTitle("AKTIONEN")

                LazyVGrid(
                    columns: actionColumns,
                    spacing: metric(9, 10)
                ) {
                    ForEach(actionOptions) { option in
                        selectionButton(for: option, compact: true)
                    }
                }

                if usesProfileBasedSelection {
                    Label("Passend zur Zielnummer angezeigt", systemImage: "checkmark.shield.fill")
                        .font(.system(size: metric(13, 14), weight: .semibold, design: .rounded))
                        .foregroundStyle(SecretMatchTheme.muted)
                }
            }
            .padding(.horizontal, metric(16, 17))
            .padding(.vertical, metric(14, 14))

            if selectedActions.contains("normal") || selectedActions.contains("hot") {
                panelDivider

                optionalMessageSection
                    .padding(.horizontal, metric(16, 17))
                    .padding(.vertical, metric(13, 14))
            }

            panelDivider

            sendButton
                .padding(.horizontal, metric(16, 17))
                .padding(.vertical, metric(13, 14))
        }
        .background(SecretMatchTheme.surfaceRaised.opacity(highContrast ? 0.78 : 0.38))
        .overlay {
            Rectangle()
                .stroke(
                    SecretMatchTheme.border.opacity(highContrast ? 1 : 0.95),
                    lineWidth: highContrast ? 2 : 1
                )
        }
    }

    private var confirmedTargetSection: some View {
        HStack(spacing: metric(12, 13)) {
            Image(systemName: "number")
                .font(.system(size: metric(18, 20), weight: .bold))
                .foregroundStyle(SecretMatchTheme.secondary)

            VStack(alignment: .leading, spacing: 2) {
                panelSectionTitle("ZIELNUMMER")
                Text(targetNumber.displayEventNumber)
                    .font(.system(size: metric(25, 28), weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white)
            }

            Spacer()

            Button("Nummer ändern") {
                onEditTarget()
            }
            .font(.system(size: metric(14, 15), weight: .bold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(SecretMatchTheme.secondary)
            .padding(.horizontal, metric(12, 13))
            .frame(minHeight: metric(42, 44))
            .background(SecretMatchTheme.surfaceRaised)
            .overlay(Rectangle().stroke(SecretMatchTheme.border, lineWidth: highContrast ? 2 : 1))
        }
    }

    private func panelSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: metric(13, 14), weight: .bold, design: .rounded))
            .tracking(1.2)
            .foregroundStyle(SecretMatchTheme.secondary)
    }

    private var panelDivider: some View {
        Rectangle()
            .fill(SecretMatchTheme.border.opacity(highContrast ? 1 : 0.9))
            .frame(height: highContrast ? 2 : 1)
            .accessibilityHidden(true)
    }

    private var targetNumberSection: some View {
        VStack(alignment: .leading, spacing: metric(8, 8)) {
            panelSectionTitle("ZIELNUMMER")

            HStack(spacing: metric(12, 13)) {
                Image(systemName: "number")
                    .font(.system(size: metric(19, 21), weight: .bold))
                    .foregroundStyle(SecretMatchTheme.secondary)
                    .frame(width: metric(24, 26))

                Text(targetNumber.isEmpty ? "Nummer eingeben" : targetNumber.displayEventNumber)
                    .foregroundStyle(targetNumber.isEmpty ? SecretMatchTheme.muted : .white)
                    .font(.system(size: metric(24, 28), weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: metric(13, 14), weight: .bold))
                    .foregroundStyle(SecretMatchTheme.muted)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, metric(14, 15))
            .frame(maxWidth: .infinity, minHeight: metric(64, 70), alignment: .leading)
            .background(Color.black.opacity(highContrast ? 1 : 0.3))
            .overlay {
                Rectangle()
                    .stroke(
                        showKeyboard ? SecretMatchTheme.primary : SecretMatchTheme.border.opacity(highContrast ? 1 : 0.95),
                        lineWidth: highContrast ? 2.5 : (showKeyboard ? 1.5 : 1)
                    )
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.2)) {
                    showTextKeyboard = false
                    showKeyboard = true
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(targetNumber.isEmpty ? "Zielnummer eingeben" : "Zielnummer \(targetNumber.displayEventNumber)")
            .accessibilityHint("Öffnet die appinterne Zahlentastatur")
            .accessibilityAddTraits(.isButton)
        }
    }

    private var optionalMessageSection: some View {
        VStack(alignment: .leading, spacing: metric(10, 8)) {
            panelSectionTitle("NACHRICHT ZUM MATCH · OPTIONAL")

            if !quickMessages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: metric(8, 8)) {
                        ForEach(quickMessages, id: \.self) { option in
                            let isSelected = matchMessage == option

                            Button {
                                selectQuickMessage(option)
                            } label: {
                                HStack(spacing: metric(7, 7)) {
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                    Text(option)
                                        .lineLimit(1)
                                }
                                .font(.system(size: metric(15, 16), weight: .bold, design: .rounded))
                                .foregroundStyle(isSelected ? Color.black : Color.white)
                                .padding(.horizontal, metric(14, 14))
                                .frame(minHeight: metric(42, 42))
                                .background(
                                    isSelected
                                        ? SecretMatchTheme.secondary
                                        : SecretMatchTheme.surfaceRaised
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            isSelected
                                                ? SecretMatchTheme.secondary
                                                : SecretMatchTheme.border,
                                            lineWidth: isSelected ? 2 : 1
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                        }
                    }
                }
            }

            if replacedCustomMessage != nil {
                HStack(spacing: metric(10, 10)) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .foregroundStyle(SecretMatchTheme.secondary)

                    Text("Text durch Schnelltext ersetzt")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    Button("Rückgängig") {
                        restoreReplacedMessage()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(SecretMatchTheme.secondary)
                }
                .padding(.horizontal, metric(14, 14))
                .frame(minHeight: metric(48, 48))
                .background(SecretMatchTheme.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous)
                        .stroke(SecretMatchTheme.secondary.opacity(0.35), lineWidth: 1)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Button {
                showKeyboard = false
                showTextKeyboard = true
            } label: {
                HStack(alignment: .top, spacing: metric(12, 12)) {
                    Image(systemName: "keyboard")
                        .foregroundStyle(SecretMatchTheme.secondary)
                    Text(matchMessage.isEmpty ? "Eigene Nachricht schreiben …" : matchMessage)
                        .font(.system(size: metric(19, 20), weight: .medium, design: .rounded))
                        .foregroundStyle(matchMessage.isEmpty ? SecretMatchTheme.muted : .white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, minHeight: metric(30, 32), alignment: .topLeading)
                }
                .padding(metric(14, 13))
                .background(SecretMatchTheme.surfaceRaised)
                .overlay(Rectangle().stroke(SecretMatchTheme.border, lineWidth: highContrast ? 2 : 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(matchMessage.isEmpty ? "Eigene Match-Nachricht schreiben" : "Match-Nachricht: \(matchMessage)")
            .accessibilityHint("Öffnet die appinterne Tastatur")

            Text("\(matchMessage.count)/180")
                .font(.system(size: metric(12, 13), design: .monospaced).monospacedDigit())
                .foregroundStyle(SecretMatchTheme.muted)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    @ViewBuilder
    var body: some View {
        Group {
            if fillsAvailableSpace {
                ScrollView {
                    content
                        .padding(.horizontal, metric(30, 30))
                        .padding(.top, metric(20, 18))
                        .padding(.bottom, metric(28, 22))
                        .frame(
                            maxWidth: .infinity,
                            minHeight: max(0, (availableHeight ?? 0) - metric(40, 34)),
                            alignment: .top
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
            }
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 10) {
                if let withdrawalConfirmationMessage {
                    withdrawalFeedback(withdrawalConfirmationMessage)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if let status = floatingDeliveryStatus {
                    deliveryFeedback(status)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if queuedSendCount > 0 {
                    queueFeedback
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, fillsAvailableSpace ? metric(30, 30) : 24)
            .padding(.bottom, floatingFeedbackBottomInset)
            .shadow(color: .black.opacity(0.68), radius: 20, y: 9)
        }
        .animation(.easeOut(duration: 0.22), value: floatingDeliveryStatus)
        .animation(.easeOut(duration: 0.22), value: queuedSendCount)
        .task(id: deliveryStatus) {
            hidesDeliveredFeedback = false

            guard let deliveryStatus, case .delivered = deliveryStatus else { return }

            do {
                try await Task.sleep(for: .seconds(canUndoLastActions ? 15 : 4))
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                hidesDeliveredFeedback = true
            }
        }
    }

    private var sendButton: some View {
        Button(action: onSend) {
            HStack {
                Text(sendButtonTitle)
                Spacer()
                Image(systemName: "paperplane.fill")
            }
        }
        .buttonStyle(SecretPrimaryButtonStyle(
            fontSize: metric(21, 23),
            minHeight: metric(68, 74)
        ))
        .disabled(selectedActions.isEmpty || targetNumber.isEmpty)
        .opacity(selectedActions.isEmpty || targetNumber.isEmpty ? 0.5 : 1)
    }

    private var sendButtonTitle: String {
        let matchCount = selectedActions.filter { $0 == "normal" || $0 == "hot" }.count
        let actionCount = selectedActions.count - matchCount

        if selectedActions.isEmpty {
            return "Auswahl senden"
        }
        if actionCount == 0 {
            return matchCount == 1 ? "Match-Wunsch senden" : "\(matchCount) Match-Wünsche senden"
        }
        if matchCount == 0 {
            return actionCount == 1 ? "Aktion senden" : "\(actionCount) Aktionen senden"
        }
        return "Auswahl senden"
    }

    private var queueFeedback: some View {
        HStack(spacing: 12) {
            Image(systemName: isRetryingQueuedSends ? "arrow.trianglehead.2.clockwise.rotate.90" : "wifi.exclamationmark")
                .font(.title2.bold())
                .foregroundStyle(SecretMatchTheme.secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(InteractionQueueWording.waitingDescription(
                    reportedShipmentCount: queuedBatchCount,
                    actionCount: queuedSendCount
                ))
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                Text("Geht automatisch raus, sobald die Verbindung wieder da ist.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SecretMatchTheme.muted)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 9) {
                Button(isRetryingQueuedSends ? "Wird versucht…" : "Jetzt versuchen") {
                    onRetryQueuedSends()
                }
                .font(.subheadline.bold())
                .foregroundStyle(SecretMatchTheme.secondary)
                .disabled(isRetryingQueuedSends)

                if canUndoLastActions {
                    undoLastActionsButton
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(SecretMatchTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous)
                .stroke(SecretMatchTheme.secondary.opacity(0.9), lineWidth: 2)
        )
        .accessibilityElement(children: .contain)
    }

    private func deliveryFeedback(_ status: InteractionDeliveryStatus) -> some View {
        let presentation: (title: String, detail: String, icon: String, color: Color) = switch status {
        case .delivered(let count):
            (count == 1 ? "Ist raus! 💚" : "Alles ist raus! 💚", count == 1 ? "Deine Aktion wurde verschickt." : "Deine \(count) Aktionen wurden verschickt.", "checkmark.circle.fill", .green)
        case .queued(let count):
            ("Kein Netz – kein Problem", InteractionQueueWording.waitingDescription(reportedShipmentCount: 1, actionCount: count) + " sicher und geht automatisch raus, sobald die Verbindung wieder da ist.", "wifi.exclamationmark", .orange)
        case .partiallyDelivered(let delivered, let queued):
            ("Ein Teil ist schon raus", "\(delivered) Aktionen verschickt · \(queued) Aktionen warten noch auf Verbindung.", "arrow.trianglehead.2.clockwise.rotate.90", SecretMatchTheme.secondary)
        case .failed:
            ("Bitte kurz prüfen", deliveryErrorMessage ?? "Das hat gerade nicht geklappt. Bitte prüfe deine Eingaben und versuche es noch einmal.", "exclamationmark.triangle.fill", .red)
        }

        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: presentation.icon)
                .font(.title2.bold())
                .foregroundStyle(presentation.color)

            VStack(alignment: .leading, spacing: 4) {
                Text(presentation.title)
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                Text(presentation.detail)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SecretMatchTheme.muted)
            }
            Spacer()
            if case .delivered = status, canUndoLastActions {
                undoLastActionsButton
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(SecretMatchTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous)
                .stroke(presentation.color.opacity(0.9), lineWidth: 2)
        )
        .accessibilityElement(children: .contain)
    }

    private var undoLastActionsButton: some View {
        Button(isUndoingLastActions ? "Wird zurückgezogen…" : "Rückgängig") {
            onUndoLastActions()
        }
        .font(.subheadline.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .frame(minHeight: 40)
        .background(Color.red.opacity(highContrast ? 1 : 0.76))
        .overlay(Rectangle().stroke(Color.white.opacity(0.7), lineWidth: highContrast ? 2 : 1))
        .disabled(isUndoingLastActions)
    }

    private func withdrawalFeedback(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .font(.title2.bold())
                .foregroundStyle(.green)
            Text(message)
                .font(.headline.bold())
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(SecretMatchTheme.surfaceRaised)
        .overlay(Rectangle().stroke(Color.green.opacity(0.9), lineWidth: 2))
        .accessibilityElement(children: .combine)
    }

    private func selectionButton(for option: ActionOption, compact: Bool = false) -> some View {
        let isSelected = selectedActions.contains(option.type)
        let usesColorIndependentSelection = highContrast || differentiateWithoutColor

        return Button {
            if isSelected {
                selectedActions.remove(option.type)
            } else {
                selectedActions.insert(option.type)
            }
        } label: {
            HStack(spacing: compact ? metric(8, 8) : metric(14, 15)) {
                Text(option.emoji)
                    .font(.system(size: compact ? metric(25, 27) : metric(30, 32)))
                    .frame(width: compact ? metric(29, 31) : metric(38, 40))

                Text(option.title)
                    .font(.system(size: compact ? metric(15, 17) : metric(17, 20), weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: metric(19, 22), weight: .semibold))
            }
            .foregroundColor(usesColorIndependentSelection && isSelected ? .black : .white)
            .padding(.horizontal, compact ? metric(10, 10) : metric(15, 17))
            .frame(maxWidth: .infinity, minHeight: metric(66, 72))
            .background(
                isSelected
                    ? (usesColorIndependentSelection ? Color.white : option.color.opacity(0.9))
                    : (usesColorIndependentSelection ? Color.black : option.color.opacity(0.16))
            )
            .overlay(
                RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius)
                    .stroke(
                        isSelected ? Color.white : (usesColorIndependentSelection ? Color.white.opacity(0.9) : option.color.opacity(0.55)),
                        lineWidth: usesColorIndependentSelection ? 2.5 : (isSelected ? 2 : 1.2)
                    )
            )
            .cornerRadius(10)
            .shadow(color: isSelected ? option.color.opacity(0.28) : .clear, radius: 12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.title), \(isSelected ? "ausgewählt" : "nicht ausgewählt")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.easeOut(duration: 0.18), value: isSelected)
    }

    private func selectQuickMessage(_ option: String) {
        let previousMessage = matchMessage
        guard previousMessage != option else {
            showTextKeyboard = false
            return
        }

        let replacesCustomText = !previousMessage.isEmpty && !quickMessages.contains(previousMessage)

        withAnimation(.easeOut(duration: 0.18)) {
            matchMessage = option
            replacedCustomMessage = replacesCustomText ? previousMessage : nil
        }
        showTextKeyboard = false

        undoMessageTask?.cancel()
        guard replacesCustomText else { return }

        undoMessageTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(5))
            } catch {
                return
            }

            withAnimation(.easeOut(duration: 0.18)) {
                replacedCustomMessage = nil
            }
        }
    }

    private func restoreReplacedMessage() {
        guard let previousMessage = replacedCustomMessage else { return }
        undoMessageTask?.cancel()

        withAnimation(.easeOut(duration: 0.18)) {
            matchMessage = previousMessage
            replacedCustomMessage = nil
        }
    }
}
