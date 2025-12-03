import SwiftUI
import UIKit

struct NumberTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    @Binding var isFocused: Bool

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: NumberTextField
        var textField: UITextField?

        init(_ parent: NumberTextField) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.text = textField.text ?? ""
            }
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.isFocused = true
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.isFocused = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        context.coordinator.textField = textField

        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor.white.withAlphaComponent(0.6),
                .font: UIFont.systemFont(ofSize: 18, weight: .medium)
            ]
        )
        textField.keyboardType = .numberPad
        textField.textAlignment = .center
        textField.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        textField.textColor = .white
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 2
        textField.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        textField.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }

        if isFocused && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFocused && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }

        // WICHTIG: Sicherstellen, dass keyboardType bleibt
        if uiView.keyboardType != .numberPad {
            uiView.keyboardType = .numberPad
        }
    }
}
