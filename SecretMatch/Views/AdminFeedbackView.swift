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
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isLoading)
            .accessibilityLabel("Feedback aktualisieren")
        }
    }

    private var summary: some View {
        HStack(spacing: 10) {
            summaryCard(
                title: "Gesamt",
                value: average(of: \.rating),
                icon: "heart.fill"
            )
            summaryCard(
                title: "Funktion",
                value: average(of: \.functionalityRating),
                icon: "gearshape.fill"
            )
        }
    }

    private func summaryCard(title: String, value: Double, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(SecretMatchTheme.secondary)
            Text(value.formatted(.number.precision(.fractionLength(1))))
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("von 5 Sternen")
                .font(.caption2)
                .foregroundStyle(SecretMatchTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(SecretMatchTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(SecretMatchTheme.border))
    }

    private func feedbackCard(_ feedback: AdminFeedback) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Feedback #\(feedback.id)")
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
                .accessibilityLabel("Feedback \(feedback.id) löschen")
            }

            ratingRow("Match&Play gesamt", value: feedback.rating)
            ratingRow("App-Funktion", value: feedback.functionalityRating)

            Label(feedback.createdAt, systemImage: "clock")
                .font(.caption.monospacedDigit())
                .foregroundStyle(SecretMatchTheme.muted)
        }
        .padding(16)
        .background(SecretMatchTheme.surface.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(SecretMatchTheme.border))
    }

    private func ratingRow(_ title: String, value: Int) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= value ? "star.fill" : "star")
                        .foregroundStyle(star <= value ? SecretMatchTheme.secondary : SecretMatchTheme.muted)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(value) von 5 Sternen")
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

    private func average(of keyPath: KeyPath<AdminFeedback, Int>) -> Double {
        guard !api.adminFeedback.isEmpty else { return 0 }
        let total = api.adminFeedback.reduce(0) { $0 + $1[keyPath: keyPath] }
        return Double(total) / Double(api.adminFeedback.count)
    }

    private func loadFeedback() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await api.loadAdminFeedback()
        } catch {
            errorMessage = "Feedback konnte nicht geladen werden."
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
