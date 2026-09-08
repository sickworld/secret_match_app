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
    var showsExtendedSymbols = false
    var onActivity: () -> Void = {}
    var onClose: () -> Void = {}

    @State private var usesUppercase = true

    private let symbolRow = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", ":", "-", "⌫"]
    private let letterRows = [
        ["Q", "W", "E", "R", "T", "Z", "U", "I", "O", "P", "Ü"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L", "Ö", "Ä"],
        ["Y", "X", "C", "V", "B", "N", "M", "ß", ",", ".", "?", "!"]
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

            keyboardRow(symbolRow)
            if showsExtendedSymbols {
                keyboardRow(["@", "#", "_", "+", "=", "/", "\\", "&", "%", "$", "*", "(", ")"])
                keyboardRow(["[", "]", "{", "}", "<", ">", "|", "~", "^", ";", "'", "\"", "`"])
            }
            ForEach(letterRows, id: \.self) { row in
                keyboardRow(row)
            }

            HStack(spacing: 8) {
                if !forcesUppercase {
                    keyboardButton("⇧", color: usesUppercase ? SecretMatchTheme.secondary : SecretMatchTheme.surfaceRaised) {
                        usesUppercase.toggle()
                        onActivity()
                    }
                    .frame(width: 70)
                    .accessibilityLabel(usesUppercase ? "Kleinschreibung einschalten" : "Großschreibung einschalten")
                }

                keyboardButton("Leerzeichen", color: SecretMatchTheme.surfaceRaised) {
                    insert(" ")
                }

                if allowsNewlines {
                    keyboardButton("Neue Zeile", color: SecretMatchTheme.surfaceRaised) {
                        insert("\n")
                    }
                    .frame(width: 130)
                }

                keyboardButton(doneLabel, color: SecretMatchTheme.primary) {
                    onActivity()
                    onClose()
                }
                .frame(width: 120)
            }
        }
        .frame(maxWidth: 980)
        .padding(20)
        .background(SecretMatchTheme.surface.opacity(highContrast ? 1 : 0.96))
        .overlay(Rectangle().stroke(SecretMatchTheme.border, lineWidth: highContrast ? 2 : 1))
        .shadow(color: .black.opacity(0.42), radius: 24, y: 14)
        .onAppear {
            usesUppercase = forcesUppercase || text.isEmpty
        }
    }

    private var displayText: String {
        guard !text.isEmpty else { return placeholder }
        return obscuresText ? String(repeating: "•", count: text.count) : text
    }

    private func keyboardRow(_ keys: [String]) -> some View {
        HStack(spacing: 8) {
            ForEach(keys, id: \.self) { key in
                keyboardButton(displayedKey(key), color: SecretMatchTheme.surfaceRaised) {
                    if key == "⌫" {
                        deleteLastCharacter()
                    } else {
                        insert(typedKey(key))
                    }
                }
                .disabled(key == "⌫" && text.isEmpty)
                .opacity(key == "⌫" && text.isEmpty ? 0.45 : 1)
                .accessibilityLabel(key == "⌫" ? "Letztes Zeichen löschen" : displayedKey(key))
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
    var showsExtendedSymbols = false
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
                    showsExtendedSymbols: showsExtendedSymbols,
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
                keyboard: .text(maxCharacters: maxCharacters, allowsNewlines: allowsNewlines)
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
    var showsExtendedSymbols = false
    var onSubmit: () -> Void = {}

    var body: some View {
        ZStack {
            BrandBackground()

            VStack(spacing: 18) {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("ADMIN-EINGABE")
                            .font(.caption.bold())
                            .tracking(1.5)
                            .foregroundStyle(SecretMatchTheme.secondary)
                        Text(title)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(SecretMatchTheme.surfaceRaised)
                            .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
                    }
                    .accessibilityLabel("Tastatur schließen")
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)

                Spacer(minLength: 0)

                switch keyboard {
                case .number(let maxDigits):
                    CustomNumberKeyboard(
                        text: $text,
                        doneLabel: "Übernehmen",
                        placeholder: placeholder,
                        maxDigits: maxDigits,
                        obscuresText: isSecure,
                        showsCloseButton: false
                    ) {
                        onSubmit()
                        dismiss()
                    }
                    .padding(.bottom, 24)
                case .text(let maxCharacters, let allowsNewlines):
                    CustomTextKeyboard(
                        text: $text,
                        title: title,
                        placeholder: placeholder,
                        maxCharacters: maxCharacters,
                        doneLabel: "Übernehmen",
                        allowsNewlines: allowsNewlines,
                        obscuresText: isSecure,
                        forcesUppercase: forcesUppercase,
                        showsExtendedSymbols: showsExtendedSymbols,
                        onClose: {
                            onSubmit()
                            dismiss()
                        }
                    )
                    .padding(.horizontal, 18)
                    .padding(.bottom, 24)
                }
            }
        }
        .buttonBorderShape(.roundedRectangle(radius: SecretMatchTheme.cornerRadius))
        .tint(SecretMatchTheme.primary)
    }
}
#endif
