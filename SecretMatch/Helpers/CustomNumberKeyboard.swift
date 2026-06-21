import SwiftUI

struct CustomNumberKeyboard: View {
    @Binding var text: String
    var doneLabel = "Fertig"
    var onDone: () -> Void

    let keys: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["←", "0", "✓"]
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text(text.isEmpty ? "Nummer…" : text)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)

            VStack(spacing: 12) {
                ForEach(keys, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { key in
                            Button(action: {
                                handleTap(key)
                            }) {
                                Text(key)
                                    .frame(width: 104, height: 68)
                                    .background(key == "✓" ? Color(hex: "#d94b68") : Color.black.opacity(0.3))
                                    .foregroundColor(.white)
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .cornerRadius(14)
                            }
                        }
                    }
                }
            }

            Text("✓  \(doneLabel)")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.72))
        }
        .padding(24)
        .frame(maxWidth: 430)
        .background(Color(hex: "#3c0d1f").opacity(0.95))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
    }

    private func handleTap(_ key: String) {
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
