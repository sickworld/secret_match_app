import SwiftUI

enum ConnectionState: Equatable {
    case checking
    case online
    case offline
    case serverUnavailable
}

struct ConnectionStatusBanner: View {
    let state: ConnectionState
    let isChecking: Bool
    let retry: () -> Void

    var body: some View {
        if state != .online {
            HStack(spacing: 12) {
                if isChecking {
                    ProgressView()
                        .tint(statusColor)
                } else {
                    Image(systemName: statusIcon)
                        .font(.headline)
                        .foregroundStyle(statusColor)
                }

                Text(statusText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                Button("Neu prüfen", action: retry)
                    .font(.subheadline.bold())
                    .foregroundStyle(statusColor)
                    .frame(minHeight: 44)
                    .disabled(isChecking)
            }
            .padding(.horizontal, 18)
            .frame(minHeight: 54)
            .background(.black.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous)
                    .stroke(statusColor.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 14, y: 6)
            .frame(maxWidth: 680)
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .contain)
        }
    }

    private var statusIcon: String {
        switch state {
        case .offline:
            return "wifi.slash"
        case .serverUnavailable:
            return "exclamationmark.icloud.fill"
        case .checking, .online:
            return "wifi"
        }
    }

    private var statusColor: Color {
        switch state {
        case .offline:
            return SecretMatchTheme.danger
        case .serverUnavailable:
            return SecretMatchTheme.secondary
        case .checking, .online:
            return SecretMatchTheme.muted
        }
    }

    private var statusText: String {
        switch state {
        case .checking:
            return "Verbindung wird geprüft…"
        case .online:
            return "Verbunden"
        case .offline:
            return "Kein Internet. Deine Wünsche gehen automatisch raus, sobald die Verbindung wieder da ist."
        case .serverUnavailable:
            return "Match&Play ist gerade nicht erreichbar. Wir versuchen es automatisch weiter."
        }
    }
}
