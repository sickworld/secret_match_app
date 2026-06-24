import SwiftUI

private struct ActionOption: Identifiable {
    let type: String
    let title: String
    let icon: String

    var id: String { type }
}

struct MatchInputBox: View {
    @Binding var targetNumber: String
    @Binding var showKeyboard: Bool
    @Binding var selectedActions: Set<String>
    @Binding var responseMessage: String
    let onSend: () -> Void

    private let options = [
        ActionOption(type: "normal", title: "Hot Match", icon: "flame.fill"),
        ActionOption(type: "hot", title: "Fuck Match", icon: "heart.fill"),
        ActionOption(type: "bjob", title: "Blow-Job", icon: "wind"),
        ActionOption(type: "hjob", title: "Hand-Job", icon: "hand.raised.fill"),
        ActionOption(type: "ljob", title: "Lick-Job", icon: "mouth.fill")
    ]

    var body: some View {
        VStack(spacing: 26) {
            VStack(spacing: 6) {
                Text("MAKE A MOVE")
                    .font(.caption2.bold())
                    .tracking(2)
                    .foregroundStyle(SecretMatchTheme.secondary)

                Text("Was möchtest du senden?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Wähle eine oder mehrere Aktionen und gib die Event-Nummer ein.")
                    .font(.subheadline)
                    .foregroundStyle(SecretMatchTheme.muted)
                    .multilineTextAlignment(.center)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(options) { option in
                    selectionButton(for: option)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("An welche Nummer?")
                    .font(.caption2.bold())
                    .tracking(1.2)
                    .foregroundStyle(SecretMatchTheme.muted)

                Text(targetNumber.isEmpty ? "Nummer eingeben" : targetNumber)
                    .foregroundStyle(targetNumber.isEmpty ? SecretMatchTheme.muted : .white)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
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
            .buttonStyle(SecretPrimaryButtonStyle())
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
        .frame(maxWidth: 650)
        .padding(.horizontal, 24)
        .secretCard(cornerRadius: 24, padding: 30)
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
            HStack(spacing: 10) {
                Image(systemName: option.icon)
                Text(option.title)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                isSelected
                    ? SecretMatchTheme.primary.opacity(0.92)
                    : SecretMatchTheme.surfaceRaised
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? SecretMatchTheme.primaryHover : SecretMatchTheme.border, lineWidth: 1.2)
            )
            .cornerRadius(15)
            .shadow(color: isSelected ? SecretMatchTheme.primary.opacity(0.24) : .clear, radius: 12)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.015 : 1)
        .animation(.easeOut(duration: 0.18), value: isSelected)
    }
}
