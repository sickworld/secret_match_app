import SwiftUI

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
