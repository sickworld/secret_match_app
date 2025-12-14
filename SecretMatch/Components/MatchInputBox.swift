import SwiftUI

struct MatchInputBox: View {
    @Binding var targetNumber: String
    @Binding var showKeyboard: Bool
    @Binding var responseMessage: String
    let onSendMatch: (String) -> Void

    var body: some View {
        VStack(spacing: 25) {
            Text("Match?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

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
                .padding()
                .onTapGesture {
                    showKeyboard = true
                }

            HStack(spacing: 16) {
                Button("Hot Match") {
                    onSendMatch("normal")
                }
                .buttonStyle(MatchButtonStyle())

                Button("Fuck Match") {
                    onSendMatch("hot")
                }
                .buttonStyle(FMatchButtonStyle())
            }

            if !responseMessage.isEmpty {
                Text(responseMessage)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color(hex: "#3c0d1f").opacity(0.92))
        .frame(width: 550)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.3), radius: 20)
    }
}
