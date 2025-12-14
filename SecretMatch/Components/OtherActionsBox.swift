import SwiftUI

struct OtherActionsBox: View {
    @Binding var targetNumber: String
    @Binding var showKeyboard: Bool

    let onSendBonus: (String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Aktion schicken?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(targetNumber.isEmpty ? "Aktion schicken an" : targetNumber)
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
                .padding()

            HStack(spacing: 16) {
                Button("Blow-Job") {
                    onSendBonus("bjob")
                }
                .buttonStyle(MatchButtonStyle())

                Button("Hand-Job") {
                    onSendBonus("hjob")
                }
                .buttonStyle(MatchButtonStyle())
                
                Button("Lick-Job") {
                    onSendBonus("ljob")
                }
                .buttonStyle(MatchButtonStyle())
            }
        }
        .padding()
        .background(Color(hex: "#3c0d1f").opacity(0.92))
        .frame(width: 550)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.3), radius: 20)
    }
}
