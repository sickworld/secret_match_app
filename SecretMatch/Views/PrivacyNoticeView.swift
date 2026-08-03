import SwiftUI

struct PrivacyNoticeView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.84)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("MATCH&PLAY · DATENSCHUTZ")
                            .font(.caption.bold())
                            .tracking(1.8)
                            .foregroundStyle(SecretMatchTheme.secondary)
                        Text("Deine Privatsphäre")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
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
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Datenschutz schließen")
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        privacyPoint(
                            icon: "person.crop.circle.badge.questionmark",
                            title: "Pseudonyme Teilnahme",
                            text: "Du nutzt Match&Play ausschließlich mit deiner Eventnummer. Name, JOYclub-Profil und JOYclub-Zugangsdaten werden von der App weder abgefragt noch übernommen."
                        )

                        privacyPoint(
                            icon: "server.rack",
                            title: "Nur notwendige Eventdaten",
                            text: "Während des Events verarbeitet Match&Play deine Eventnummer, eine freiwillige Geschlechtsangabe für die ausgewogene Top-16-Auswahl, ausgewählte Aktionen, entstandene Matches und technisch notwendige Sitzungsdaten. Diese Daten werden ausschließlich für die Durchführung des Spiels verwendet."
                        )

                        privacyPoint(
                            icon: "eye.slash.fill",
                            title: "Keine Profilbildung",
                            text: "Die Daten werden nicht für Werbung, dauerhafte Profile oder eine Verknüpfung mit deinem JOYclub-Konto genutzt."
                        )

                        privacyPoint(
                            icon: "trash.fill",
                            title: "Löschung nach dem Event",
                            text: "Eventnummern, Aktionen, Matches und Sitzungen werden nach Abschluss des Events aus dem aktiven Match&Play-System gelöscht."
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Verantwortlicher Veranstalter")
                                .font(.headline)
                                .foregroundStyle(.white)

                            Text("Hot Chili Events\nKirchheimerstr. 4\n71229 Leonberg\nDeutschland")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.78))

                            Text("Für Datenschutzanfragen kannst du das Veranstaltungsteam vor Ort ansprechen.")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(SecretMatchTheme.muted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(SecretMatchTheme.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(SecretMatchTheme.border))
                        .padding(.top, 4)
                    }
                }
            }
            .frame(maxWidth: 920, maxHeight: .infinity)
            .secretCard(cornerRadius: 28, padding: 30)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
    }

    private func privacyPoint(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3.bold())
                .foregroundStyle(SecretMatchTheme.secondary)
                .frame(width: 42, height: 42)
                .background(SecretMatchTheme.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(SecretMatchTheme.border))
    }
}
