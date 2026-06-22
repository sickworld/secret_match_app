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
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("Was möchtest du senden?")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("Du kannst mehrere Aktionen auswählen.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(options) { option in
                    selectionButton(for: option)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("An welche Nummer?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.8))

                Text(targetNumber.isEmpty ? "Nummer eingeben" : targetNumber)
                    .foregroundColor(targetNumber.isEmpty ? .white.opacity(0.6) : .white)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(12)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                    )
                    .onTapGesture {
                        showKeyboard = true
                    }
            }

            Button(action: onSend) {
                Text(selectedActions.count == 1 ? "Aktion senden" : "\(selectedActions.count) Aktionen senden")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color(hex: "#F52235"))
                    .foregroundColor(.white)
                    .font(.headline)
                    .cornerRadius(12)
            }
            .disabled(selectedActions.isEmpty || targetNumber.isEmpty)
            .opacity(selectedActions.isEmpty || targetNumber.isEmpty ? 0.5 : 1)

            if !responseMessage.isEmpty {
                Text(responseMessage)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(28)
        .background(Color(hex: "#35070D").opacity(0.94))
        .frame(maxWidth: 650)
        .padding(.horizontal, 24)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.3), radius: 20)
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
            .background(isSelected ? Color(hex: "#F52235") : Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white.opacity(0.7) : Color.white.opacity(0.2), lineWidth: 1.5)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
