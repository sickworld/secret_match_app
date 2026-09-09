import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var api: APIService
    @Environment(\.secretMatchInterfaceScale) private var interfaceScale
    var secondsRemaining: Int
    var registerActivity: () -> Void
    var logout: () -> Void
    @Binding var showOverviewOverlay: Bool
    @Binding var selectedOverviewSection: ParticipantOverviewSection
    @Binding var showGuideOverlay: Bool
    @Binding var showRulesOverlay: Bool
    @Binding var showInfoOverlay: Bool
    var isCompact = false
    var isShort = false
    var availableHeight: CGFloat?

    private var normalizedScale: CGFloat {
        max(interfaceScale, 1)
    }

    private var zoomProgress: CGFloat {
        min(max((normalizedScale - 1) / 0.30, 0), 1)
    }

    private func metric(_ standard: CGFloat, _ extraLarge: CGFloat) -> CGFloat {
        let renderedValue = standard + (extraLarge - standard) * zoomProgress
        return renderedValue / normalizedScale
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: isCompact ? 150 : metric(188, 202))
                .frame(height: isCompact ? 98 : metric(126, 136))
                .frame(maxWidth: .infinity, alignment: .center)
                .shadow(color: SecretMatchTheme.primary.opacity(0.16), radius: 18)

            Spacer()
                .frame(height: isCompact ? 4 : metric(4, 3))

            eventPass

            Spacer()
                .frame(height: isCompact ? 7 : metric(7, 5))

            sidebarMenu

            Spacer(minLength: isCompact ? 8 : metric(10, 6))

            partnerLogos
        }
        .padding(.horizontal, isCompact ? 16 : metric(16, 12))
        .padding(.vertical, isCompact ? 12 : metric(16, 12))
        .frame(width: isCompact ? nil : metric(304, 336))
        .frame(maxWidth: isCompact ? .infinity : nil)
        .background(SecretMatchTheme.surface.opacity(0.97))
        .overlay(alignment: isCompact ? .bottom : .trailing) {
            Rectangle()
                .fill(SecretMatchTheme.border)
                .frame(width: isCompact ? nil : 1, height: isCompact ? 1 : nil)
        }
    }

    private var sidebarMenu: some View {
        VStack(spacing: 0) {
            overviewButton(
                "Matches",
                systemImage: "sparkles",
                section: .matches
            )

            sidebarDivider

            overviewButton(
                "Interesse",
                systemImage: "heart.text.square.fill",
                section: .interests
            )

            sidebarDivider

            overviewButton(
                "Erhaltene Aktionen",
                systemImage: "tray.and.arrow.down.fill",
                section: .actions
            )

            sidebarDivider

            utilityButton(
                "So geht's",
                systemImage: "questionmark.circle.fill",
                accessibilityLabel: "So funktioniert's"
            ) {
                showGuideOverlay = true
            }

            sidebarDivider

            utilityButton(
                "Regeln",
                systemImage: "book.closed.fill",
                accessibilityLabel: "Spielregeln"
            ) {
                showRulesOverlay = true
            }

            sidebarDivider

            utilityButton(
                "Info",
                systemImage: "info.circle.fill",
                accessibilityLabel: "Info und Support"
            ) {
                showInfoOverlay = true
            }
            .accessibilityHint("Öffnet Feedback, Datenschutz und Impressum")

            sidebarDivider

            Button {
                logout()
            } label: {
                HStack(spacing: isCompact ? 12 : metric(12, 13)) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: isCompact ? 18 : metric(18, 20), weight: .bold))
                        .frame(width: isCompact ? 24 : metric(24, 26))

                    Text("Abmelden")

                    Spacer(minLength: 0)
                }
                .foregroundStyle(SecretMatchTheme.danger)
            }
            .buttonStyle(flatRowStyle(tint: SecretMatchTheme.danger))

            logoutStatus
        }
        .background(SecretMatchTheme.surfaceRaised.opacity(0.42))
        .overlay {
            Rectangle()
                .stroke(SecretMatchTheme.border.opacity(0.9), lineWidth: 1)
        }
    }

    private var logoutStatus: some View {
        HStack(spacing: isCompact ? 11 : metric(11, 12)) {
            Circle()
                .fill(secondsRemaining <= 10 ? SecretMatchTheme.secondary : SecretMatchTheme.primary)
                .frame(
                    width: isCompact ? 10 : metric(10, 11),
                    height: isCompact ? 10 : metric(10, 11)
                )
                .shadow(
                    color: (secondsRemaining <= 10 ? SecretMatchTheme.secondary : SecretMatchTheme.primary).opacity(0.45),
                    radius: 5
                )

            Text("Auto-Logout in \(secondsRemaining)s")
                .font(.system(
                    size: isCompact ? 16 : metric(16, 18),
                    weight: secondsRemaining <= 10 ? .heavy : .semibold,
                    design: .rounded
                ))
                .foregroundStyle(secondsRemaining <= 10 ? SecretMatchTheme.secondary : SecretMatchTheme.muted)
                .monospacedDigit()

            Spacer(minLength: 0)
        }
        .padding(.horizontal, isCompact ? 12 : metric(12, 13))
        .frame(minHeight: isCompact ? 42 : metric(42, 42))
        .background(SecretMatchTheme.surface.opacity(0.38))
        .accessibilityLabel("Automatischer Logout in \(secondsRemaining) Sekunden")
    }

    private var eventPass: some View {
        HStack(spacing: isCompact ? 12 : metric(12, 13)) {
            VStack(alignment: .leading, spacing: 4) {
                Text("DEIN EVENT PASS")
                    .font(.caption2.bold())
                    .tracking(1.3)
                    .foregroundStyle(SecretMatchTheme.secondary)

                Text(api.number.displayEventNumber)
                    .font(.system(
                        size: isCompact ? 28 : metric(28, 31),
                        weight: .heavy,
                        design: .rounded
                    ))
                    .foregroundStyle(.white)
            }

            Spacer(minLength: 0)

            Image(systemName: "ticket.fill")
                .font(.system(size: isCompact ? 22 : metric(22, 24), weight: .bold))
                .foregroundStyle(SecretMatchTheme.primary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, isCompact ? 12 : metric(12, 13))
        .frame(minHeight: isCompact ? 68 : metric(70, 72))
    }

    private var partnerLogos: some View {
        Group {
            if managedSponsorItems.isEmpty {
                bundledPartnerLogos
            } else {
                TimelineView(.periodic(from: .now, by: 6)) { context in
                    let index = Int(context.date.timeIntervalSince1970 / 6) % managedSponsorItems.count
                    let item = managedSponsorItems[index]
                    if let image = api.cachedScreensaverImage(for: item) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: isCompact ? 190 : metric(190, 198))
                            .managedMediaBackdrop(
                                item.useLightBackground,
                                insets: EdgeInsets(top: 4, leading: 7, bottom: 4, trailing: 7)
                            )
                            .accessibilityLabel(item.title.isEmpty ? "Sponsorbild" : item.title)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: isCompact ? 66 : metric(62, 58), alignment: .center)
    }

    private var managedSponsorItems: [ScreensaverMediaItem] {
        api.screensaverItems.filter { $0.enabled && $0.showAsSponsor }
    }

    private var bundledPartnerLogos: some View {
        HStack(alignment: .center, spacing: isCompact ? 4 : metric(5, 5)) {
            Image("hot-chili")
                .resizable()
                .scaledToFit()
                .frame(
                    width: isCompact ? 58 : metric(64, 64),
                    height: isCompact ? 42 : metric(48, 46)
                )
                .shadow(color: SecretMatchTheme.primary.opacity(0.18), radius: 12)
                .accessibilityLabel("Hot Chili Events")

            Image("ficken-logo")
                .resizable()
                .scaledToFit()
                .frame(
                    width: isCompact ? 62 : metric(68, 68),
                    height: isCompact ? 34 : metric(38, 36)
                )
                .padding(.horizontal, isCompact ? 6 : metric(6, 6))
                .padding(.vertical, isCompact ? 4 : metric(4, 4))
                .background(Color.white.opacity(0.94))
                .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
                .accessibilityLabel("FICKEN Likör")

            Image("club2020")
                .resizable()
                .scaledToFit()
                .frame(
                    width: isCompact ? 112 : metric(98, 94),
                    height: isCompact ? 76 : metric(68, 64)
                )
                .accessibilityLabel("Club 2020")
        }
    }

    private var sidebarDivider: some View {
        Rectangle()
            .fill(SecretMatchTheme.border.opacity(0.9))
            .frame(height: 1)
            .accessibilityHidden(true)
    }

    private func flatRowStyle(tint: Color = SecretMatchTheme.primary) -> FlatSidebarRowStyle {
        FlatSidebarRowStyle(
            fontSize: isCompact ? 18 : metric(18, 20),
            minHeight: isCompact ? 56 : metric(56, 58),
            horizontalPadding: isCompact ? 12 : metric(12, 13),
            tint: tint
        )
    }

    private func overviewButton(
        _ title: String,
        systemImage: String,
        section: ParticipantOverviewSection
    ) -> some View {
        Button {
            registerActivity()
            selectedOverviewSection = section
            showOverviewOverlay = true
        } label: {
            sidebarRowLabel(title, systemImage: systemImage)
        }
        .buttonStyle(flatRowStyle())
        .accessibilityHint("Öffnet direkt den Bereich \(title)")
    }

    private func utilityButton(
        _ title: String,
        systemImage: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            registerActivity()
            action()
        } label: {
            sidebarRowLabel(title, systemImage: systemImage)
        }
        .buttonStyle(flatRowStyle(tint: SecretMatchTheme.secondary))
        .accessibilityLabel(accessibilityLabel)
    }

    private func sidebarRowLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: isCompact ? 10 : metric(10, 11)) {
            Image(systemName: systemImage)
                .font(.system(size: isCompact ? 19 : metric(19, 21), weight: .bold))
                .foregroundStyle(SecretMatchTheme.secondary)
                .frame(width: isCompact ? 24 : metric(24, 26))

            Text(title)

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: isCompact ? 13 : metric(13, 14), weight: .bold))
                .foregroundStyle(SecretMatchTheme.muted)
                .accessibilityHidden(true)
        }
    }
}

private struct FlatSidebarRowStyle: ButtonStyle {
    let fontSize: CGFloat
    let minHeight: CGFloat
    let horizontalPadding: CGFloat
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .contentShape(Rectangle())
            .background(configuration.isPressed ? tint.opacity(0.13) : Color.clear)
            .foregroundStyle(.white)
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}
