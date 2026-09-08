import SwiftUI

struct ParticipantGenderView: View {
    let isSubmitting: Bool
    let errorMessage: String?
    let onSelect: (ParticipantGender) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.84)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("KURZER EVENT-CHECK")
                    .font(.caption.bold())
                    .tracking(2)
                    .foregroundStyle(SecretMatchTheme.secondary)

                Text("Wie möchtest du dich einordnen?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Die Angabe bleibt pseudonym und ist für die Teilnahme erforderlich.")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(SecretMatchTheme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 16) {
                    genderButton(.female)
                    genderButton(.male)
                }

                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(SecretMatchTheme.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: 700)
            .secretCard(padding: 34)
            .padding(.horizontal, 28)
        }
    }

    private func genderButton(_ gender: ParticipantGender) -> some View {
        Button {
            onSelect(gender)
        } label: {
            VStack(spacing: 10) {
                Text(gender.symbol)
                    .font(.system(size: 44, weight: .medium, design: .rounded))
                Text(gender.title)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 116)
            .background(SecretMatchTheme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius).stroke(SecretMatchTheme.border, lineWidth: 1.2))
        }
        .disabled(isSubmitting)
    }
}
