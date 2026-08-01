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
    @Binding var selectedActions: Set<String>
    @Binding var responseMessage: String
    let onSend: () -> Void
    var fillsAvailableSpace = false

    private let options = [
        ActionOption(type: "normal", title: "Hot Match", emoji: "❤️", color: Color(hex: "#E83E8C")),
        ActionOption(type: "hot", title: "Fuck Match", emoji: "🍆", color: Color(hex: "#8E63D2")),
        ActionOption(type: "bjob", title: "Blow-Job", emoji: "👄", color: Color(hex: "#3E9ED6")),
        ActionOption(type: "hjob", title: "Hand-Job", emoji: "✋", color: Color(hex: "#E6923E")),
        ActionOption(type: "ljob", title: "Lick-Job", emoji: "👅", color: Color(hex: "#D65C8D"))
    ]

    private var content: some View {
        VStack(spacing: 26) {
            VStack(spacing: 6) {
                Text("MAKE A MOVE")
                    .font(.caption2.bold())
                    .tracking(2)
                    .foregroundStyle(SecretMatchTheme.secondary)

                Text("Was möchtest du senden?")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Wähle eine oder mehrere Aktionen und gib die Event-Nummer ein.")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(SecretMatchTheme.muted)
                    .multilineTextAlignment(.center)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(options) { option in
                    selectionButton(for: option)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("ZIEL-NUMMER")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(SecretMatchTheme.secondary)

                Text(targetNumber.isEmpty ? "Ziel-Nummer eingeben" : targetNumber)
                    .foregroundStyle(targetNumber.isEmpty ? SecretMatchTheme.muted : .white)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.78)
                    .secretInput(highlighted: showKeyboard)
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showKeyboard = true
                        }
                    }
            }

            Button(action: onSend) {
                HStack {
                    Text(selectedActions.count == 1 ? "Aktion senden" : "\(selectedActions.count) Aktionen senden")
                    Spacer()
                    Image(systemName: "paperplane.fill")
                }
            }
            .buttonStyle(SecretPrimaryButtonStyle(fontSize: 21, minHeight: 80))
            .disabled(selectedActions.isEmpty || targetNumber.isEmpty)
            .opacity(selectedActions.isEmpty || targetNumber.isEmpty ? 0.5 : 1)

            if !responseMessage.isEmpty {
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
        .frame(maxWidth: 780)
    }

    @ViewBuilder
    var body: some View {
        if fillsAvailableSpace {
            content
                .padding(.horizontal, 30)
                .padding(.top, 24)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity, minHeight: 0, alignment: .top)
        } else {
            content
                .padding(.horizontal, 24)
                .secretCard(cornerRadius: 24, padding: 30)
        }
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
                    .font(.system(size: 30))
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
            .frame(maxWidth: .infinity, minHeight: 72)
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
