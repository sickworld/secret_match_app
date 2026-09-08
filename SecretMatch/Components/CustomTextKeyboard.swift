import SwiftUI

struct CustomTextKeyboard: View {
    @Environment(\.secretMatchHighContrast) private var highContrast
    @Binding var text: String
    var title = "NACHRICHT ZUM MATCH"
    var placeholder = "Schreibe eine kurze Nachricht …"
    var maxCharacters = 180
    var doneLabel = "Fertig"
    var allowsNewlines = false
    var obscuresText = false
    var forcesUppercase = false
    var onActivity: () -> Void = {}
    var onClose: () -> Void = {}

    @State private var usesUppercase = true
    @State private var page: KeyboardPage = .letters

    private let letterRows = [
        ["Q", "W", "E", "R", "T", "Z", "U", "I", "O", "P", "Ü"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L", "Ö", "Ä"]
    ]
    private let numberRows = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["@", "#", "€", "_", "&", "-", "+", "(", ")", "/"]
    ]
    private let symbolRows = [
        ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="],
        ["_", "\\", "|", "~", "<", ">", "$", "£", "¥", "•"]
    ]
    private let emojiRows = [
        ["😀", "😂", "😍", "🥰", "😘", "😉", "😊", "😎", "🥳", "🤩"],
        ["❤️", "🔥", "✨", "🎉", "👍", "👏", "🙌", "🤝", "💃", "🕺"],
        ["🍻", "🥂", "🍹", "☕️", "🎵", "📍", "⏰", "🚀", "💬", "✅"]
    ]

    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title.uppercased())
                        .font(.caption.bold())
                        .tracking(1.4)
                        .foregroundStyle(SecretMatchTheme.secondary)
                    Spacer()
                    Text("\(text.count)/\(maxCharacters)")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(SecretMatchTheme.muted)
                }

                Text(displayText)
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                    .foregroundStyle(text.isEmpty ? SecretMatchTheme.muted : .white)
                    .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
                    .lineLimit(3)
                    .padding(12)
                    .background(Color.black.opacity(highContrast ? 1 : 0.3))
                    .overlay(Rectangle().stroke(SecretMatchTheme.border, lineWidth: highContrast ? 2 : 1))
            }

            keyboardKeys
            bottomRow
        }
        .frame(maxWidth: 980)
        .padding(20)
        .background(SecretMatchTheme.surface.opacity(highContrast ? 1 : 0.96))
        .overlay(Rectangle().stroke(SecretMatchTheme.border, lineWidth: highContrast ? 2 : 1))
        .shadow(color: .black.opacity(0.42), radius: 24, y: 14)
        .onAppear {
            usesUppercase = forcesUppercase || text.isEmpty
            page = .letters
        }
    }

    @ViewBuilder
    private var keyboardKeys: some View {
        switch page {
        case .letters:
            keyboardRow(letterRows[0])
            keyboardRow(letterRows[1], horizontalInset: 28)
            HStack(spacing: 8) {
                keyboardButton("⇧", color: usesUppercase ? SecretMatchTheme.secondary : SecretMatchTheme.surfaceRaised) {
                    guard !forcesUppercase else { return }
                    usesUppercase.toggle()
                    onActivity()
                }
                .frame(width: 72)
                .accessibilityLabel(
                    forcesUppercase
                        ? "Großschreibung fest eingestellt"
                        : (usesUppercase ? "Kleinschreibung einschalten" : "Großschreibung einschalten")
                )

                ForEach(["Y", "X", "C", "V", "B", "N", "M", "ß", ",", "."], id: \.self) { key in
                    characterButton(key)
                }

                deleteButton
            }
        case .numbers:
            keyboardRow(numberRows[0])
            keyboardRow(numberRows[1], horizontalInset: 28)
            HStack(spacing: 8) {
                keyboardButton("#+=", color: SecretMatchTheme.surfaceRaised) {
                    switchPage(to: .symbols)
                }
                .frame(width: 72)
                keyboardRowContent([".", ",", "?", "!", "'", "\"", ":", ";", "§"])
                deleteButton
            }
        case .symbols:
            keyboardRow(symbolRows[0])
            keyboardRow(symbolRows[1], horizontalInset: 28)
            HStack(spacing: 8) {
                keyboardButton("123", color: SecretMatchTheme.surfaceRaised) {
                    switchPage(to: .numbers)
                }
                .frame(width: 72)
                keyboardRowContent([".", ",", "?", "!", "'", "\"", ":", ";", "`"])
                deleteButton
            }
        case .emoji:
            ForEach(emojiRows, id: \.self) { row in
                keyboardRow(row)
            }
        }
    }

    private var bottomRow: some View {
        HStack(spacing: 8) {
            keyboardButton(page == .letters ? "123" : "ABC", color: SecretMatchTheme.surfaceRaised) {
                switchPage(to: page == .letters ? .numbers : .letters)
            }
            .frame(width: 82)

            keyboardButton(page == .emoji ? "#+=" : "😊", color: SecretMatchTheme.surfaceRaised) {
                switchPage(to: page == .emoji ? .symbols : .emoji)
            }
            .frame(width: 68)
            .accessibilityLabel(page == .emoji ? "Sonderzeichen anzeigen" : "Emojis anzeigen")

            keyboardButton("Leerzeichen", color: SecretMatchTheme.surfaceRaised) {
                insert(" ")
            }

            if allowsNewlines {
                keyboardButton("Neue Zeile", color: SecretMatchTheme.surfaceRaised) {
                    insert("\n")
                }
                .frame(width: 132)
            }

            keyboardButton(doneLabel, color: SecretMatchTheme.primary) {
                onActivity()
                onClose()
            }
            .frame(width: 132)
        }
    }

    private var displayText: String {
        guard !text.isEmpty else { return placeholder }
        return obscuresText ? String(repeating: "•", count: text.count) : text
    }

    private func keyboardRow(_ keys: [String], horizontalInset: CGFloat = 0) -> some View {
        HStack(spacing: 8) {
            keyboardRowContent(keys)
        }
        .padding(.horizontal, horizontalInset)
    }

    private func keyboardRowContent(_ keys: [String]) -> some View {
        ForEach(keys, id: \.self) { key in
            characterButton(key)
        }
    }

    private func characterButton(_ key: String) -> some View {
        keyboardButton(displayedKey(key), color: SecretMatchTheme.surfaceRaised) {
            insert(typedKey(key))
        }
        .accessibilityLabel(displayedKey(key))
    }

    private var deleteButton: some View {
        keyboardButton("⌫", color: SecretMatchTheme.surfaceRaised) {
            deleteLastCharacter()
        }
        .frame(width: 72)
        .disabled(text.isEmpty)
        .opacity(text.isEmpty ? 0.45 : 1)
        .accessibilityLabel("Letztes Zeichen löschen")
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
                .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous)
                        .stroke(SecretMatchTheme.border, lineWidth: highContrast ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func displayedKey(_ key: String) -> String {
        key.rangeOfCharacter(from: .letters) == nil || forcesUppercase || usesUppercase ? key : key.lowercased()
    }

    private func typedKey(_ key: String) -> String {
        displayedKey(key)
    }

    private func insert(_ value: String) {
        onActivity()
        guard text.count < maxCharacters else { return }
        text.append(contentsOf: value.prefix(maxCharacters - text.count))

        if forcesUppercase {
            usesUppercase = true
        } else if value == "." || value == "?" || value == "!" {
            usesUppercase = true
        } else if value.rangeOfCharacter(from: .letters) != nil {
            usesUppercase = false
        }
    }

    private func deleteLastCharacter() {
        onActivity()
        guard !text.isEmpty else { return }
        text.removeLast()
    }

    private func switchPage(to newPage: KeyboardPage) {
        onActivity()
        page = newPage
    }

    private enum KeyboardPage {
        case letters
        case numbers
        case symbols
        case emoji
    }
}

enum AdminKeyboardKind {
    case number(maxDigits: Int)
    case text(maxCharacters: Int, allowsNewlines: Bool = false)
}

/// Uses the regular iOS input on the standalone Admin app and the event app's
/// large in-app keyboard in the integrated iPad admin area.
struct AdminKeyboardTextField: View {
    let title: String
    @Binding var text: String
    var keyboard: AdminKeyboardKind
    var keyboardTitle: String? = nil
    var isSecure = false
    var forcesUppercase = false
    var doneLabel = "Fertig"
    var onSubmit: () -> Void = {}

    @State private var showsKeyboard = false

    var body: some View {
#if ADMIN_APP
        nativeField
#else
        keyboardButton
            .fullScreenCover(isPresented: $showsKeyboard) {
                AdminKeyboardEntryView(
                    text: $text,
                    title: keyboardTitle ?? title,
                    placeholder: title,
                    keyboard: keyboard,
                    isSecure: isSecure,
                    forcesUppercase: forcesUppercase,
                    doneLabel: doneLabel,
                    onSubmit: onSubmit
                )
            }
#endif
    }

#if ADMIN_APP
    @ViewBuilder
    private var nativeField: some View {
        if isSecure {
            SecureField(title, text: $text)
                .onSubmit(onSubmit)
        } else {
            TextField(title, text: $text)
                .keyboardType(nativeKeyboardType)
                .onSubmit(onSubmit)
        }
    }

    private var nativeKeyboardType: UIKeyboardType {
        if case .number = keyboard { return .numberPad }
        return .default
    }
#else
    private var keyboardButton: some View {
        Button {
            showsKeyboard = true
        } label: {
            HStack(spacing: 10) {
                Text(fieldText)
                    .foregroundStyle(text.isEmpty ? Color.secondary : Color.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "keyboard")
                    .font(.callout.bold())
                    .foregroundStyle(SecretMatchTheme.secondary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(text.isEmpty ? title : "\(title): \(isSecure ? "ausgefüllt" : text)")
        .accessibilityHint("Öffnet die App-Tastatur")
    }

    private var fieldText: String {
        guard !text.isEmpty else { return title }
        return isSecure ? String(repeating: "•", count: text.count) : text
    }
#endif
}

struct AdminKeyboardTextEditor: View {
    let title: String
    @Binding var text: String
    var maxCharacters: Int
    var allowsNewlines = false
    var doneLabel = "Fertig"

    @State private var showsKeyboard = false

    var body: some View {
#if ADMIN_APP
        TextEditor(text: $text)
#else
        Button {
            showsKeyboard = true
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Text(text.isEmpty ? title : text)
                    .foregroundStyle(text.isEmpty ? Color.secondary : Color.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(5)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                Image(systemName: "keyboard")
                    .font(.callout.bold())
                    .foregroundStyle(SecretMatchTheme.secondary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(text.isEmpty ? title : "\(title): \(text)")
        .accessibilityHint("Öffnet die App-Tastatur")
        .fullScreenCover(isPresented: $showsKeyboard) {
            AdminKeyboardEntryView(
                text: $text,
                title: title,
                placeholder: title,
                keyboard: .text(maxCharacters: maxCharacters, allowsNewlines: allowsNewlines),
                doneLabel: doneLabel
            )
        }
#endif
    }
}

#if !ADMIN_APP
private struct AdminKeyboardEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var text: String
    let title: String
    let placeholder: String
    let keyboard: AdminKeyboardKind
    var isSecure = false
    var forcesUppercase = false
    var doneLabel = "Fertig"
    var onSubmit: () -> Void = {}

    var body: some View {
        ZStack {
            Color.black.opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack {
                Spacer(minLength: 12)

                switch keyboard {
                case .number(let maxDigits):
                    CustomNumberKeyboard(
                        text: $text,
                        doneLabel: doneLabel,
                        placeholder: placeholder,
                        maxDigits: maxDigits,
                        obscuresText: isSecure,
                        onClose: { dismiss() }
                    ) {
                        onSubmit()
                        dismiss()
                    }
                    .frame(maxWidth: 740)
                    .padding()
                    .shadow(radius: 20)
                case .text(let maxCharacters, let allowsNewlines):
                    CustomTextKeyboard(
                        text: $text,
                        title: title,
                        placeholder: placeholder,
                        maxCharacters: maxCharacters,
                        doneLabel: doneLabel,
                        allowsNewlines: allowsNewlines,
                        obscuresText: isSecure,
                        forcesUppercase: forcesUppercase,
                        onClose: {
                            onSubmit()
                            dismiss()
                        }
                    )
                    .padding(18)
                }

                Spacer(minLength: 12)
            }
            .transition(.scale(scale: 0.94).combined(with: .opacity))
        }
        .presentationBackground(.clear)
        .buttonBorderShape(.roundedRectangle(radius: SecretMatchTheme.cornerRadius))
        .tint(SecretMatchTheme.primary)
    }

    private var backgroundOpacity: Double {
        if case .text = keyboard { return 0.72 }
        return 0.6
    }
}
#endif
