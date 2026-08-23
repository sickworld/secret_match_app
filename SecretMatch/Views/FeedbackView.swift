import SwiftUI

struct FeedbackView: View {
    @EnvironmentObject private var api: APIService
    @Binding var isPresented: Bool

    @State private var rating: Int?
    @State private var experience: Experience?
    @State private var comment = ""
    @State private var isSubmitting = false
    @State private var didSubmit = false
    @State private var errorMessage: String?

    private let maximumCommentLength = 500

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
            .secretCard(cornerRadius: 28, padding: 30)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
    }

    private var formContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                question("Wie gefällt dir Match&Play?") {
                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { value in
                            Button {
                                rating = value
                                errorMessage = nil
                            } label: {
                                Image(systemName: value <= (rating ?? 0) ? "star.fill" : "star")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(value <= (rating ?? 0) ? SecretMatchTheme.secondary : SecretMatchTheme.muted)
                                    .frame(maxWidth: .infinity, minHeight: 58)
                                    .background(SecretMatchTheme.surfaceRaised)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(rating == value ? SecretMatchTheme.secondary : SecretMatchTheme.border, lineWidth: 1.2)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(value) von 5 Sternen")
                            .accessibilityAddTraits(rating == value ? .isSelected : [])
                        }
                    }
                }

                question("Hat alles funktioniert?") {
                    HStack(spacing: 10) {
                        ForEach(Experience.allCases) { option in
                            Button {
                                experience = option
                                errorMessage = nil
                            } label: {
                                Text(option.title)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, minHeight: 52)
                                    .background(experience == option ? SecretMatchTheme.primary.opacity(0.35) : SecretMatchTheme.surfaceRaised)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(experience == option ? SecretMatchTheme.primary : SecretMatchTheme.border, lineWidth: 1.2)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(experience == option ? .isSelected : [])
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Möchtest du uns noch etwas sagen?")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("Optional")
                            .font(.caption.bold())
                            .foregroundStyle(SecretMatchTheme.muted)
                    }

                    TextEditor(text: $comment)
                        .font(.body)
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100)
                        .padding(12)
                        .background(Color.black.opacity(0.28))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SecretMatchTheme.border))
                        .onChange(of: comment) { _, newValue in
                            if newValue.count > maximumCommentLength {
                                comment = String(newValue.prefix(maximumCommentLength))
                            }
                        }

                    Text("\(comment.count)/\(maximumCommentLength)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(SecretMatchTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .trailing)
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
                .clipShape(Circle())
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

    private func submit() {
        guard let rating, let experience else {
            errorMessage = "Bitte beantworte die beiden kurzen Fragen."
            return
        }

        isSubmitting = true
        errorMessage = nil
        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                try await api.submitFeedback(
                    rating: rating,
                    experience: experience.rawValue,
                    comment: trimmedComment
                )
                didSubmit = true
            } catch {
                errorMessage = "Das Feedback konnte gerade nicht gesendet werden. Bitte versuche es noch einmal."
            }
            isSubmitting = false
        }
    }
}

private extension FeedbackView {
    enum Experience: String, CaseIterable, Identifiable {
        case yes
        case partly
        case no

        var id: String { rawValue }

        var title: String {
            switch self {
            case .yes: "Ja"
            case .partly: "Teilweise"
            case .no: "Nein"
            }
        }
    }
}
