import SwiftUI

struct CustomNumberKeyboard: View {
    @Binding var text: String
    var doneLabel = "Fertig"
    var onActivity: () -> Void = {}
    var onDone: () -> Void

    let keys: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["←", "0", "✓"]
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("EVENT-NUMMER")
                .font(.caption2.bold())
                .tracking(1.8)
                .foregroundStyle(SecretMatchTheme.secondary)

            Text(text.isEmpty ? "Nummer…" : text)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)

            VStack(spacing: 12) {
                ForEach(keys, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { key in
                            Button(action: {
                                handleTap(key)
                            }) {
                                Text(key)
                                    .frame(width: 104, height: 68)
                                    .background(key == "✓" ? SecretMatchTheme.primary : SecretMatchTheme.surfaceRaised)
                                    .foregroundStyle(.white)
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
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

            Text("✓  \(doneLabel)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SecretMatchTheme.muted)
        }
        .frame(maxWidth: 430)
        .secretCard(cornerRadius: 22, padding: 24)
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
