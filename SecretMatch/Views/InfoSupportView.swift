import SwiftUI

struct InfoSupportView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var api: APIService

    @State private var showFeedback = false
    @State private var showPrivacy = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.84)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(alignment: .leading, spacing: 20) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Button {
                            showFeedback = true
                        } label: {
                            infoRow(
                                icon: "bubble.left.and.bubble.right.fill",
                                title: "Feedback geben",
                                subtitle: "Vier anonyme Sternfragen – dauert weniger als eine Minute"
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            showPrivacy = true
                        } label: {
                            infoRow(
                                icon: "lock.shield.fill",
                                title: "Datenschutz",
                                subtitle: "Welche Eventdaten verarbeitet und wann gelöscht werden"
                            )
                        }
                        .buttonStyle(.plain)

                        impressum

                        Text("Match&Play · Version \(appVersion) (\(buildNumber))")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(SecretMatchTheme.muted)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }
                }
            }
            .frame(maxWidth: 760, maxHeight: 820)
            .secretCard(padding: 30)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)

            if showPrivacy {
                PrivacyNoticeView(isPresented: $showPrivacy)
                    .zIndex(2)
            }

            if showFeedback {
                FeedbackView(isPresented: $showFeedback)
                    .environmentObject(api)
                    .zIndex(2)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("MATCH&PLAY")
                    .font(.caption.bold())
                    .tracking(1.8)
                    .foregroundStyle(SecretMatchTheme.secondary)
                Text("Info & Support")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Hilfe, Datenschutz und Anbieterinformationen")
                    .font(.subheadline)
                    .foregroundStyle(SecretMatchTheme.muted)
            }

            Spacer()

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
            .accessibilityLabel("Info und Support schließen")
        }
    }

    private func infoRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3.bold())
                .foregroundStyle(SecretMatchTheme.secondary)
                .frame(width: 46, height: 46)
                .background(SecretMatchTheme.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(SecretMatchTheme.muted)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.subheadline.bold())
                .foregroundStyle(SecretMatchTheme.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SecretMatchTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius).stroke(SecretMatchTheme.border))
    }

    private var impressum: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Impressum", systemImage: "building.2.fill")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Anbieter und verantwortlich für Match&Play")
                .font(.caption.bold())
                .foregroundStyle(SecretMatchTheme.secondary)

            Text("Hot Chili Events\nKirchheimerstr. 4\n71229 Leonberg\nDeutschland")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))

            Text("Für direkte Fragen kannst du außerdem das Veranstaltungsteam vor Ort ansprechen.")
                .font(.footnote)
                .foregroundStyle(SecretMatchTheme.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius).stroke(SecretMatchTheme.border))
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "–"
    }
}
