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
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("NUMMER EINGEBEN")
                        .font(.caption.bold())
                        .tracking(1.8)
                        .foregroundStyle(SecretMatchTheme.secondary)
                    Text("Event-Tastatur")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button {
                    onActivity()
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(SecretMatchTheme.surfaceRaised)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Tastatur schließen")
            }

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
                                    .frame(maxWidth: .infinity, minHeight: 78)
                                    .background(key == "✓" ? SecretMatchTheme.primary : SecretMatchTheme.surfaceRaised)
                                    .foregroundStyle(.white)
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
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
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(SecretMatchTheme.muted)
        }
        .frame(maxWidth: 480)
        .secretCard(cornerRadius: 28, padding: 28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
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
