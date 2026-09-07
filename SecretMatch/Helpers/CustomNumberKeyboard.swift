import SwiftUI

struct CustomNumberKeyboard: View {
    @Environment(\.secretMatchInterfaceScale) private var interfaceScale
    @Binding var text: String
    var doneLabel = "Fertig"
    var placeholder = "Nummer…"
    var maxDigits = 3
    var obscuresText = false
    var showsCloseButton = true
    var onActivity: () -> Void = {}
    var onClose: () -> Void = {}
    var onDone: () -> Void

    let keys: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["←", "0", "✓"]
    ]

    private var isZoomed: Bool { interfaceScale > 1.01 }
    private var isExtraLarge: Bool { interfaceScale >= 1.29 }

    var body: some View {
        VStack(spacing: isZoomed ? 16 : 24) {
            Text(text.isEmpty ? placeholder : (obscuresText ? String(repeating: "•", count: text.count) : text.displayEventNumber))
                .font(.system(size: isZoomed ? 36 : 44, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.trailing, 44)

            VStack(spacing: isZoomed ? 10 : 14) {
                ForEach(keys, id: \.self) { row in
                    HStack(spacing: isZoomed ? 10 : 14) {
                        ForEach(row, id: \.self) { key in
                            Button(action: {
                                handleTap(key)
                            }) {
                                Text(key)
                                    .frame(maxWidth: .infinity, minHeight: isExtraLarge ? 74 : (isZoomed ? 82 : 94))
                                    .background(key == "✓" ? SecretMatchTheme.primary : SecretMatchTheme.surfaceRaised)
                                    .foregroundStyle(.white)
                                    .font(.system(size: isZoomed ? 34 : 40, weight: .bold, design: .rounded))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(key == "✓" ? SecretMatchTheme.primaryHover : SecretMatchTheme.border)
                                    )
                                    .shadow(color: key == "✓" ? SecretMatchTheme.primary.opacity(0.25) : .clear, radius: 12)
                            }
                            .accessibilityLabel(key == "✓" ? doneLabel : (key == "←" ? "Löschen" : key))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: 700)
        .secretCard(cornerRadius: 30, padding: isExtraLarge ? 22 : (isZoomed ? 26 : 32))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if showsCloseButton {
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
        }
        .padding(.horizontal, isZoomed ? 14 : 20)
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
            if text.count < maxDigits {
                text.append(key)
            }
        }
    }
}
