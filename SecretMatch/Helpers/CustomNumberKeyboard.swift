import SwiftUI

struct CustomNumberKeyboard: View {
    @Environment(\.secretMatchInterfaceScale) private var interfaceScale
    @Environment(\.secretMatchHighContrast) private var highContrast
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
            ZStack {
                Text(text.isEmpty ? placeholder : (obscuresText ? String(repeating: "•", count: text.count) : text.displayEventNumber))
                    .font(.system(size: isZoomed ? 36 : 44, weight: .bold, design: .rounded))
                    .foregroundStyle(text.isEmpty ? SecretMatchTheme.muted : .white)
                    .frame(maxWidth: .infinity)

                if showsCloseButton {
                    HStack {
                        Spacer()
                        Button {
                            onActivity()
                            onClose()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(SecretMatchTheme.surfaceRaised)
                                .overlay(Rectangle().stroke(SecretMatchTheme.border, lineWidth: highContrast ? 2 : 1))
                        }
                        .accessibilityLabel("Tastatur schließen")
                    }
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: isZoomed ? 66 : 76)
            .background(Color.black.opacity(highContrast ? 1 : 0.3))
            .overlay(Rectangle().stroke(SecretMatchTheme.border, lineWidth: highContrast ? 2 : 1))

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
                                    .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius)
                                            .stroke(key == "✓" ? SecretMatchTheme.primaryHover : SecretMatchTheme.border, lineWidth: highContrast ? 2 : 1)
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
        .padding(isExtraLarge ? 22 : (isZoomed ? 26 : 32))
        .background(SecretMatchTheme.surface.opacity(highContrast ? 1 : 0.96))
        .overlay(Rectangle().stroke(SecretMatchTheme.border, lineWidth: highContrast ? 2 : 1))
        .shadow(color: .black.opacity(0.42), radius: 24, y: 14)
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
