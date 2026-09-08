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
    var queuedSendCount = 0
    var queuedBatchCount = 0
    var isRetryingQueuedSends = false
    var deliveryStatus: InteractionDeliveryStatus?
    var deliveryErrorMessage: String?
    var onRetryQueuedSends: () -> Void = {}
    var fillsAvailableSpace = false
    var availableHeight: CGFloat?

    private let options = [
        ActionOption(type: "normal", title: "Hot Match", emoji: "❤️", color: Color(hex: "#E83E8C")),
        ActionOption(type: "hot", title: "Fuck Match", emoji: "🍆", color: Color(hex: "#8E63D2")),
        ActionOption(type: "bjob", title: "Blow-Job", emoji: "👄", color: Color(hex: "#3E9ED6")),
        ActionOption(type: "hjob", title: "Hand-Job", emoji: "✋", color: Color(hex: "#E6923E")),
        ActionOption(type: "ljob", title: "Lick-Job", emoji: "👅", color: Color(hex: "#D65C8D"))
    ]

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

    private var pinsSendButton: Bool {
        fillsAvailableSpace
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
        pinsSendButton ? metric(112, 122) : 124
    }

    private var content: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("MAKE A MOVE")
                    .font(.caption2.bold())
                    .tracking(2)
                    .foregroundStyle(SecretMatchTheme.secondary)

                Text("Was möchtest du senden?")
                    .font(.system(size: metric(34, 40), weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Wähle eine oder mehrere Aktionen und gib die Event-Nummer ein.")
                    .font(.system(size: metric(17, 19), weight: .medium, design: .rounded))
                    .foregroundStyle(SecretMatchTheme.muted)
                    .multilineTextAlignment(.center)
            }

            Color.clear
                .frame(height: fillsAvailableSpace ? metric(22, 20) : 26)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: fillsAvailableSpace ? metric(12, 12) : 12
            ) {
                ForEach(options) { option in
                    selectionButton(for: option)
                }
            }

            Color.clear
                .frame(height: fillsAvailableSpace ? metric(34, 28) : 26)

            VStack(alignment: .leading, spacing: 8) {
                Text("ZIEL-NUMMER")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(SecretMatchTheme.secondary)

                Text(targetNumber.isEmpty ? "Ziel-Nummer eingeben" : targetNumber.displayEventNumber)
                    .foregroundStyle(targetNumber.isEmpty ? SecretMatchTheme.muted : .white)
                    .font(.system(size: metric(34, 40), weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.78)
                    .secretInput(highlighted: showKeyboard)
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showKeyboard = true
                        }
                    }
            }

            if selectedActions.contains("normal") || selectedActions.contains("hot") {
                Spacer(minLength: 18)
                VStack(alignment: .leading, spacing: 10) {
                    Text("NACHRICHT ZUM MATCH · OPTIONAL")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(SecretMatchTheme.secondary)
                    if !quickMessages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(quickMessages, id: \.self) { option in
                                    let isSelected = matchMessage == option

                                    Button {
                                        selectQuickMessage(option)
                                    } label: {
                                        HStack(spacing: 7) {
                                            if isSelected {
                                                Image(systemName: "checkmark.circle.fill")
                                            }
                                            Text(option)
                                                .lineLimit(1)
                                        }
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(isSelected ? Color.black : Color.white)
                                        .padding(.horizontal, 14)
                                        .frame(minHeight: 42)
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
                        HStack(spacing: 10) {
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
                        .padding(.horizontal, 14)
                        .frame(minHeight: 48)
                        .background(SecretMatchTheme.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(SecretMatchTheme.secondary.opacity(0.35), lineWidth: 1)
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Button {
                        showKeyboard = false
                        showTextKeyboard = true
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "keyboard")
                                .foregroundStyle(SecretMatchTheme.secondary)
                            Text(matchMessage.isEmpty ? "Eigene Nachricht schreiben …" : matchMessage)
                                .font(.system(size: 19, weight: .medium, design: .rounded))
                                .foregroundStyle(matchMessage.isEmpty ? SecretMatchTheme.muted : .white)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, minHeight: 30, alignment: .topLeading)
                        }
                        .padding(14)
                        .background(SecretMatchTheme.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(matchMessage.isEmpty ? "Eigene Match-Nachricht schreiben" : "Match-Nachricht: \(matchMessage)")
                    .accessibilityHint("Öffnet die appinterne Tastatur")
                    Text("\(matchMessage.count)/180")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(SecretMatchTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            if !pinsSendButton {
                Spacer(minLength: 26)
                sendButton
            }

        }
        .frame(
            maxWidth: fillsAvailableSpace ? .infinity : 780,
            minHeight: fillsAvailableSpace
                ? max(0, (availableHeight ?? 0) - metric(105, 105))
                : nil,
            alignment: .top
        )
    }

    @ViewBuilder
    var body: some View {
        Group {
            if fillsAvailableSpace {
                VStack(spacing: 0) {
                    ScrollView {
                        content
                            .padding(.horizontal, metric(30, 30))
                            .padding(.top, metric(24, 20))
                            .padding(.bottom, metric(30, 20))
                            .frame(
                                maxWidth: .infinity,
                                minHeight: max(0, (availableHeight ?? 0) - metric(105, 105)),
                                alignment: .top
                            )
                    }

                    if pinsSendButton {
                        Divider()
                            .overlay(SecretMatchTheme.border)

                        sendButton
                            .padding(.horizontal, metric(30, 30))
                            .padding(.vertical, metric(12, 12))
                            .background(SecretMatchTheme.surface.opacity(0.98))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content
                    .padding(.horizontal, 24)
                    .secretCard(cornerRadius: 24, padding: 30)
            }
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 10) {
                if let status = floatingDeliveryStatus {
                    deliveryFeedback(status)
                        .allowsHitTesting(false)
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
                try await Task.sleep(for: .seconds(4))
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
                Text(selectedActions.count == 1 ? "Aktion senden" : "\(selectedActions.count) Aktionen senden")
                Spacer()
                Image(systemName: "paperplane.fill")
            }
        }
        .buttonStyle(SecretPrimaryButtonStyle(
            fontSize: metric(21, 23),
            minHeight: metric(80, 86)
        ))
        .disabled(selectedActions.isEmpty || targetNumber.isEmpty)
        .opacity(selectedActions.isEmpty || targetNumber.isEmpty ? 0.5 : 1)
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

            Button(isRetryingQueuedSends ? "Wird versucht…" : "Jetzt versuchen") {
                onRetryQueuedSends()
            }
            .font(.subheadline.bold())
            .foregroundStyle(SecretMatchTheme.secondary)
            .disabled(isRetryingQueuedSends)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(SecretMatchTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
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
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(SecretMatchTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(presentation.color.opacity(0.9), lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
    }

    private func selectionButton(for option: ActionOption) -> some View {
        let isSelected = selectedActions.contains(option.type)
        let usesColorIndependentSelection = highContrast || differentiateWithoutColor

        return Button {
            if isSelected {
                selectedActions.remove(option.type)
            } else {
                selectedActions.insert(option.type)
            }
        } label: {
            HStack(spacing: metric(14, 15)) {
                Text(option.emoji)
                    .font(.system(size: metric(30, 32)))
                    .frame(width: metric(38, 40))

                Text(option.title)
                    .font(.system(size: metric(17, 20), weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: metric(19, 22), weight: .semibold))
            }
            .foregroundColor(usesColorIndependentSelection && isSelected ? .black : .white)
            .padding(.horizontal, metric(16, 18))
            .frame(maxWidth: .infinity, minHeight: metric(72, 80))
            .background(
                isSelected
                    ? (usesColorIndependentSelection ? Color.white : option.color.opacity(0.9))
                    : (usesColorIndependentSelection ? Color.black : option.color.opacity(0.16))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        isSelected ? Color.white : (usesColorIndependentSelection ? Color.white.opacity(0.9) : option.color.opacity(0.55)),
                        lineWidth: usesColorIndependentSelection ? 2.5 : (isSelected ? 2 : 1.2)
                    )
            )
            .cornerRadius(15)
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
