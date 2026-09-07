import SwiftUI

struct CustomTextKeyboard: View {
    @Binding var text: String
    var maxCharacters = 180
    var onActivity: () -> Void = {}
    var onClose: () -> Void = {}

    @State private var usesUppercase = true

    private let symbolRow = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", ":", "-"]
    private let letterRows = [
        ["Q", "W", "E", "R", "T", "Z", "U", "I", "O", "P", "Ü"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L", "Ö", "Ä"],
        ["Y", "X", "C", "V", "B", "N", "M", "ß", ",", ".", "?", "!"]
    ]

    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("NACHRICHT ZUM MATCH")
                        .font(.caption.bold())
                        .tracking(1.4)
                        .foregroundStyle(SecretMatchTheme.secondary)
                    Spacer()
                    Text("\(text.count)/\(maxCharacters)")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(SecretMatchTheme.muted)
                }

                Text(text.isEmpty ? "Schreibe eine kurze Nachricht …" : text)
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                    .foregroundStyle(text.isEmpty ? SecretMatchTheme.muted : .white)
                    .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
                    .lineLimit(3)
                    .padding(12)
                    .background(Color.black.opacity(0.24))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            keyboardRow(symbolRow)
            ForEach(letterRows, id: \.self) { row in
                keyboardRow(row)
            }

            HStack(spacing: 8) {
                keyboardButton("⇧", color: usesUppercase ? SecretMatchTheme.secondary : SecretMatchTheme.surfaceRaised) {
                    usesUppercase.toggle()
                    onActivity()
                }
                .frame(width: 70)
                .accessibilityLabel(usesUppercase ? "Kleinschreibung einschalten" : "Großschreibung einschalten")

                keyboardButton("Leerzeichen", color: SecretMatchTheme.surfaceRaised) {
                    insert(" ")
                }

                keyboardButton("⌫", color: SecretMatchTheme.surfaceRaised) {
                    onActivity()
                    guard !text.isEmpty else { return }
                    text.removeLast()
                }
                .frame(width: 86)
                .accessibilityLabel("Letztes Zeichen löschen")

                keyboardButton("Fertig", color: SecretMatchTheme.primary) {
                    onActivity()
                    onClose()
                }
                .frame(width: 120)
            }
        }
        .frame(maxWidth: 980)
        .secretCard(cornerRadius: 26, padding: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .onAppear {
            usesUppercase = text.isEmpty
        }
    }

    private func keyboardRow(_ keys: [String]) -> some View {
        HStack(spacing: 8) {
            ForEach(keys, id: \.self) { key in
                keyboardButton(displayedKey(key), color: SecretMatchTheme.surfaceRaised) {
                    insert(typedKey(key))
                }
                .accessibilityLabel(displayedKey(key))
            }
        }
    }

    private func keyboardButton(
        _ title: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func displayedKey(_ key: String) -> String {
        key.rangeOfCharacter(from: .letters) == nil || usesUppercase ? key : key.lowercased()
    }

    private func typedKey(_ key: String) -> String {
        displayedKey(key)
    }

    private func insert(_ value: String) {
        onActivity()
        guard text.count < maxCharacters else { return }
        text.append(contentsOf: value.prefix(maxCharacters - text.count))

        if value == "." || value == "?" || value == "!" {
            usesUppercase = true
        } else if value.rangeOfCharacter(from: .letters) != nil {
            usesUppercase = false
        }
    }
}
