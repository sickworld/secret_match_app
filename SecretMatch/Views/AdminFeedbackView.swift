import SwiftUI

struct AdminFeedbackView: View {
    @EnvironmentObject private var api: APIService

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var feedbackToDelete: AdminFeedback?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if !api.adminFeedback.isEmpty {
                    summary
                }

                if let errorMessage, !api.adminFeedback.isEmpty {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SecretMatchTheme.danger)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SecretMatchTheme.danger.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
                }

                if isLoading && api.adminFeedback.isEmpty {
                    ProgressView("Feedback wird geladen…")
                        .tint(.white)
                        .foregroundStyle(SecretMatchTheme.muted)
                        .frame(maxWidth: .infinity, minHeight: 180)
                } else if let errorMessage, api.adminFeedback.isEmpty {
                    errorState(errorMessage)
                } else if api.adminFeedback.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(api.adminFeedback) { feedback in
                            feedbackCard(feedback)
                        }
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .task { await loadFeedback() }
        .refreshable { await loadFeedback() }
        .confirmationDialog(
            "Feedback löschen?",
            isPresented: Binding(
                get: { feedbackToDelete != nil },
                set: { if !$0 { feedbackToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Löschen", role: .destructive) {
                guard let feedback = feedbackToDelete else { return }
                feedbackToDelete = nil
                Task { await delete(feedback) }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Dieser anonyme Eintrag wird dauerhaft entfernt.")
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("EVENT CONTROL")
                    .font(.caption.bold())
                    .tracking(2)
                    .foregroundStyle(SecretMatchTheme.secondary)
                Text("Feedback")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Anonyme Sternebewertungen aus der Teilnehmer-App")
                    .font(.subheadline)
                    .foregroundStyle(SecretMatchTheme.muted)
            }

            Spacer(minLength: 0)

            Button {
                Task { await loadFeedback() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.headline.bold())
                    .frame(width: 48, height: 48)
                    .foregroundStyle(.white)
                    .background(SecretMatchTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
            }
            .disabled(isLoading)
            .accessibilityLabel("Feedback aktualisieren")
        }
    }

    private var summary: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 135), spacing: 10)], spacing: 10) {
            summaryCard(
                title: "Gesamt",
                value: averageText(of: \.rating),
                icon: "heart.fill"
            )
            summaryCard(
                title: "Funktion",
                value: averageText(of: \.functionalityRating),
                icon: "gearshape.fill"
            )
            summaryCard(
                title: "Bedienung",
                value: averageText(of: \.easeOfUseRating),
                icon: "hand.tap.fill"
            )
            summaryCard(
                title: "Design",
                value: averageText(of: \.designRating),
                icon: "paintpalette.fill"
            )
        }
    }

    private func summaryCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(SecretMatchTheme.secondary)
            Text(value)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("von 5 Sternen")
                .font(.caption2)
                .foregroundStyle(SecretMatchTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(SecretMatchTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius).stroke(SecretMatchTheme.border))
    }

    private func feedbackCard(_ feedback: AdminFeedback) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Anonymes Feedback")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button(role: .destructive) {
                    feedbackToDelete = feedback
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 44, height: 44)
                        .foregroundStyle(SecretMatchTheme.danger)
                }
                .accessibilityLabel("Anonymes Feedback löschen")
            }

            ratingRow("Match&Play gesamt", value: feedback.rating)
            ratingRow("App-Funktion", value: feedback.functionalityRating)
            ratingRow("Bedienung", value: feedback.easeOfUseRating)
            ratingRow("Design", value: feedback.designRating)
        }
        .padding(16)
        .background(SecretMatchTheme.surface.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius).stroke(SecretMatchTheme.border))
    }

    private func ratingRow(_ title: String, value: Int?) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
            if let value {
                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= value ? "star.fill" : "star")
                            .foregroundStyle(star <= value ? SecretMatchTheme.secondary : SecretMatchTheme.muted)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(value) von 5 Sternen")
            } else {
                Text("Nicht beantwortet")
                    .font(.caption)
                    .foregroundStyle(SecretMatchTheme.muted)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.bubble")
                .font(.system(size: 48))
                .foregroundStyle(SecretMatchTheme.secondary)
            Text("Noch kein Feedback")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("Sobald Gäste eine Bewertung senden, erscheint sie hier.")
                .font(.subheadline)
                .foregroundStyle(SecretMatchTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(SecretMatchTheme.danger)
                .multilineTextAlignment(.center)
            Button("Erneut versuchen") {
                Task { await loadFeedback() }
            }
            .buttonStyle(SecretSecondaryButtonStyle())
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }

    private func averageText(of keyPath: KeyPath<AdminFeedback, Int?>) -> String {
        let values = api.adminFeedback.compactMap { $0[keyPath: keyPath] }
        guard !values.isEmpty else { return "–" }
        let average = Double(values.reduce(0, +)) / Double(values.count)
        return average.formatted(.number.precision(.fractionLength(1)))
    }

    private func loadFeedback() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await api.loadAdminFeedback()
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ feedback: AdminFeedback) async {
        do {
            try await api.deleteAdminFeedback(id: feedback.id)
        } catch {
            errorMessage = "Feedback konnte nicht gelöscht werden."
        }
    }
}
