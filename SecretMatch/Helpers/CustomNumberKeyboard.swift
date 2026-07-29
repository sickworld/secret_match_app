import SwiftUI

struct CustomNumberKeyboard: View {
    @Binding var text: String
    var doneLabel = "Fertig"
    var onActivity: () -> Void = {}
    var onClose: () -> Void = {}
    var onDone: () -> Void

    let keys: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["←", "0", "✓"]
    ]

    var body: some View {
        VStack(spacing: 24) {
            Text(text.isEmpty ? "Nummer…" : text)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.trailing, 44)

            VStack(spacing: 14) {
                ForEach(keys, id: \.self) { row in
                    HStack(spacing: 14) {
                        ForEach(row, id: \.self) { key in
                            Button(action: {
                                handleTap(key)
                            }) {
                                Text(key)
                                    .frame(maxWidth: .infinity, minHeight: 94)
                                    .background(key == "✓" ? SecretMatchTheme.primary : SecretMatchTheme.surfaceRaised)
                                    .foregroundStyle(.white)
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(key == "✓" ? SecretMatchTheme.primaryHover : SecretMatchTheme.border)
                                    )
                                    .shadow(color: key == "✓" ? SecretMatchTheme.primary.opacity(0.25) : .clear, radius: 12)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: 570)
        .secretCard(cornerRadius: 30, padding: 32)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Button {
                onActivity()
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(SecretMatchTheme.surfaceRaised)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Tastatur schließen")
            .padding(20)
        }
        .padding(.horizontal, 20)
    }

    private func handleTap(_ key: String) {
        onActivity()

        switch key {
        case "←":
            if !text.isEmpty {
                text.removeLast()
            }
        case "✓":
            onDone()
        default:
            if text.count < 4 {
                text.append(key)
            }
        }
    }
}
