import SwiftUI

struct FeedbackView: View {
    @EnvironmentObject private var api: APIService
    @Binding var isPresented: Bool

    @State private var overallRating: Int?
    @State private var functionalityRating: Int?
    @State private var easeOfUseRating: Int?
    @State private var designRating: Int?
    @State private var isSubmitting = false
    @State private var didSubmit = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black.opacity(0.84)
                .ignoresSafeArea()
                .onTapGesture {
                    guard !isSubmitting else { return }
                    isPresented = false
                }

            Group {
                if didSubmit {
                    successContent
                } else {
                    formContent
                }
            }
            .frame(maxWidth: 760)
            .secretCard(padding: 30)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
    }

    private var formContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                question("Wie gefällt dir Match&Play?") {
                    starPicker(selection: $overallRating)
                }

                question("Wie gut hat die App funktioniert?") {
                    starPicker(selection: $functionalityRating)
                }

                question("Wie einfach war die Bedienung?") {
                    starPicker(selection: $easeOfUseRating)
                }

                question("Wie gut gefällt dir das Design?") {
                    starPicker(selection: $designRating)
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SecretMatchTheme.danger)
                }

                Button(action: submit) {
                    HStack(spacing: 10) {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        }
                        Text(isSubmitting ? "Wird gesendet…" : "Anonym absenden")
                    }
                }
                .buttonStyle(SecretPrimaryButtonStyle())
                .disabled(isSubmitting)

                Label("Wir senden keine Eventnummer mit deinem Feedback.", systemImage: "eye.slash.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(SecretMatchTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("MATCH&PLAY · FEEDBACK")
                    .font(.caption.bold())
                    .tracking(1.8)
                    .foregroundStyle(SecretMatchTheme.secondary)
                Text("Sag uns kurz deine Meinung")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Dauert weniger als eine Minute.")
                    .font(.subheadline)
                    .foregroundStyle(SecretMatchTheme.muted)
            }

            Spacer()

            closeButton
        }
    }

    private var closeButton: some View {
        Button {
            isPresented = false
        } label: {
            Image(systemName: "xmark")
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(SecretMatchTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
        }
        .disabled(isSubmitting)
        .accessibilityLabel("Feedback schließen")
    }

    private var successContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(SecretMatchTheme.primary)
            Text("Danke für dein Feedback!")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Damit hilfst du uns, Match&Play noch besser zu machen.")
                .font(.body)
                .foregroundStyle(SecretMatchTheme.muted)
                .multilineTextAlignment(.center)
            Button("Zurück zur App") {
                isPresented = false
            }
            .buttonStyle(SecretPrimaryButtonStyle())
        }
        .padding(.vertical, 20)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isModal)
    }

    private func question<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            content()
        }
    }

    private func starPicker(selection: Binding<Int?>) -> some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    selection.wrappedValue = value
                    errorMessage = nil
                } label: {
                    Image(systemName: value <= (selection.wrappedValue ?? 0) ? "star.fill" : "star")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(value <= (selection.wrappedValue ?? 0) ? SecretMatchTheme.secondary : SecretMatchTheme.muted)
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .background(SecretMatchTheme.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius)
                                .stroke(selection.wrappedValue == value ? SecretMatchTheme.secondary : SecretMatchTheme.border, lineWidth: 1.2)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(value) von 5 Sternen")
                .accessibilityAddTraits(selection.wrappedValue == value ? .isSelected : [])
            }
        }
    }

    private func submit() {
        guard let overallRating,
              let functionalityRating,
              let easeOfUseRating,
              let designRating else {
            errorMessage = "Bitte bewerte alle vier Fragen mit Sternen."
            return
        }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                try await api.submitFeedback(
                    rating: overallRating,
                    functionalityRating: functionalityRating,
                    easeOfUseRating: easeOfUseRating,
                    designRating: designRating
                )
                didSubmit = true
            } catch {
                errorMessage = "Das Feedback konnte gerade nicht gesendet werden. Bitte versuche es noch einmal."
            }
            isSubmitting = false
        }
    }
}
