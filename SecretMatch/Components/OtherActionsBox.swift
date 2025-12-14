import SwiftUI

struct OtherActionsBox: View {
    @Binding var targetNumber: String
    @Binding var showKeyboard: Bool
    @Binding var responseMessage: String

    let onSendAction: (String) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Aktion senden")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // 📱 Eingabefeld
            Text(targetNumber.isEmpty ? "Nummer eingeben" : targetNumber)
                .foregroundColor(targetNumber.isEmpty ? .white.opacity(0.6) : .white)
                .frame(width: 500, height: 55)
                .background(Color.black.opacity(0.4))
                .cornerRadius(12)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                )
                .onTapGesture {
                    showKeyboard = true
                }
                .padding(.bottom, 10)

            // 🎯 Bonus-Aktionen
            HStack(spacing: 16) {
                ActionButton(label: "Blow-Job", type: "bjob")
                ActionButton(label: "Hand-Job", type: "hjob")
                ActionButton(label: "Lick-Job", type: "ljob")
            }

            if !responseMessage.isEmpty {
                Text(responseMessage)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(hex: "#3c0d1f").opacity(0.92))
        .frame(width: 550)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.3), radius: 20)
    }

    func ActionButton(label: String, type: String) -> some View {
        Button(action: {
            onSendAction(type)
        }) {
            Text(label)
                .frame(minWidth: 80)
        }
        .buttonStyle(MatchButtonStyle())
    }
}
