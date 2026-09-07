import SwiftUI

private struct ActionOption: Identifiable {
    let type: String
    let title: String
    let emoji: String
    let color: Color

    var id: String { type }
}

struct MatchInputBox: View {
    @Binding var targetNumber: String
    @Binding var showKeyboard: Bool
    @Binding var showTextKeyboard: Bool
    @Binding var selectedActions: Set<String>
    @Binding var responseMessage: String
    @Binding var matchMessage: String
    let quickMessages: [String]
    let onSend: () -> Void
    var queuedSendCount = 0
    var isRetryingQueuedSends = false
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

    private var isHeightConstrained: Bool {
        fillsAvailableSpace && (availableHeight ?? .infinity) < 700
    }

    private var pinsSendButton: Bool {
        fillsAvailableSpace && isHeightConstrained
    }

    private var content: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("MAKE A MOVE")
                    .font(.caption2.bold())
                    .tracking(2)
                    .foregroundStyle(SecretMatchTheme.secondary)

                Text("Was möchtest du senden?")
                    .font(.system(size: isHeightConstrained ? 30 : 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Wähle eine oder mehrere Aktionen und gib die Event-Nummer ein.")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(SecretMatchTheme.muted)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: isHeightConstrained ? 14 : (fillsAvailableSpace ? 22 : 26))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(options) { option in
                    selectionButton(for: option)
                }
            }

            Spacer(minLength: isHeightConstrained ? 18 : (fillsAvailableSpace ? 34 : 26))

            VStack(alignment: .leading, spacing: 8) {
                Text("ZIEL-NUMMER")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(SecretMatchTheme.secondary)

                Text(targetNumber.isEmpty ? "Ziel-Nummer eingeben" : targetNumber.displayEventNumber)
                    .foregroundStyle(targetNumber.isEmpty ? SecretMatchTheme.muted : .white)
                    .font(.system(size: isHeightConstrained ? 30 : 34, weight: .bold, design: .rounded))
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
                                    Button(option) {
                                        matchMessage = option
                                        showTextKeyboard = false
                                    }
                                        .buttonStyle(.bordered)
                                        .tint(SecretMatchTheme.secondary)
                                }
                            }
                        }
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
                Spacer(minLength: isHeightConstrained ? 18 : (fillsAvailableSpace ? 28 : 26))
                sendButton
            }

            if queuedSendCount > 0 {
                Spacer(minLength: 16)

                HStack(spacing: 12) {
                    Image(systemName: isRetryingQueuedSends ? "arrow.trianglehead.2.clockwise.rotate.90" : "wifi.exclamationmark")
                        .foregroundStyle(SecretMatchTheme.secondary)

                    Text(queuedSendCount == 1 ? "1 Aktion wartet aufs Senden" : "\(queuedSendCount) Aktionen warten aufs Senden")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    Button(isRetryingQueuedSends ? "Wird versucht…" : "Jetzt versuchen") {
                        onRetryQueuedSends()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(SecretMatchTheme.secondary)
                    .disabled(isRetryingQueuedSends)
                }
                .padding(14)
                .background(SecretMatchTheme.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(SecretMatchTheme.secondary.opacity(0.35)))
            }

            if !responseMessage.isEmpty {
                Spacer(minLength: 20)

                Text(responseMessage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(SecretMatchTheme.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(SecretMatchTheme.primary.opacity(0.3)))
            }
        }
        .frame(
            maxWidth: 780,
            minHeight: fillsAvailableSpace ? max(0, (availableHeight ?? 0) - 54) : nil
        )
    }

    @ViewBuilder
    var body: some View {
        if fillsAvailableSpace {
            VStack(spacing: 0) {
                ScrollView {
                    content
                        .padding(.horizontal, 30)
                        .padding(.top, isHeightConstrained ? 18 : 24)
                        .padding(.bottom, isHeightConstrained ? 18 : 30)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: pinsSendButton ? 0 : max(0, (availableHeight ?? 0) - 54),
                            alignment: .top
                        )
                }

                if pinsSendButton {
                    Divider()
                        .overlay(SecretMatchTheme.border)

                    sendButton
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
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

    private var sendButton: some View {
        Button(action: onSend) {
            HStack {
                Text(selectedActions.count == 1 ? "Aktion senden" : "\(selectedActions.count) Aktionen senden")
                Spacer()
                Image(systemName: "paperplane.fill")
            }
        }
        .buttonStyle(SecretPrimaryButtonStyle(
            fontSize: isHeightConstrained ? 19 : 21,
            minHeight: isHeightConstrained ? 68 : 80
        ))
        .disabled(selectedActions.isEmpty || targetNumber.isEmpty)
        .opacity(selectedActions.isEmpty || targetNumber.isEmpty ? 0.5 : 1)
    }

    private func selectionButton(for option: ActionOption) -> some View {
        let isSelected = selectedActions.contains(option.type)

        return Button {
            if isSelected {
                selectedActions.remove(option.type)
            } else {
                selectedActions.insert(option.type)
            }
        } label: {
            HStack(spacing: 14) {
                Text(option.emoji)
                    .font(.system(size: isHeightConstrained ? 27 : 30))
                    .frame(width: 38)

                Text(option.title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 19, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: isHeightConstrained ? 62 : 72)
            .background(
                isSelected
                    ? option.color.opacity(0.9)
                    : option.color.opacity(0.16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(option.color.opacity(isSelected ? 1 : 0.55), lineWidth: isSelected ? 2 : 1.2)
            )
            .cornerRadius(15)
            .shadow(color: isSelected ? option.color.opacity(0.28) : .clear, radius: 12)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.015 : 1)
        .animation(.easeOut(duration: 0.18), value: isSelected)
    }
}
