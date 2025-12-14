import SwiftUI

struct CustomNumberKeyboard: View {
    @Binding var text: String
    var onDone: () -> Void

    let keys: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["←", "0", "✓"]
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text(text.isEmpty ? "Nummer…" : text)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)

            VStack(spacing: 10) {
                ForEach(keys, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { key in
                            Button(action: {
                                handleTap(key)
                            }) {
                                Text(key)
                                    .frame(width: 70, height: 50)
                                    .background(Color.black.opacity(0.3))
                                    .foregroundColor(.white)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: 500)
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
