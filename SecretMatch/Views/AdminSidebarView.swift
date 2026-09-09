import SwiftUI

struct AdminSidebarView: View {
    @EnvironmentObject var api: APIService

    @Binding var showBillboard: Bool
    @Binding var dashboardSection: AdminDashboardSection
    var dismissMenu: () -> Void = {}
    var logout: () -> Void
    var isCompact = false

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 12 : 18) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: isCompact ? 132 : 174)
                .frame(height: isCompact ? 86 : 142)
                .shadow(color: SecretMatchTheme.primary.opacity(0.16), radius: 18)

            Text("EVENT CONTROL")
                .font(.caption2.bold())
                .tracking(1.8)
                .foregroundStyle(SecretMatchTheme.secondary)

            Divider().background(Color.white.opacity(0.3))

#if ADMIN_APP
            navigationButton(.overview, title: "Dashboard")
            ForEach(AdminDashboardSection.featureSections) { section in
                navigationButton(section)
            }
#else
            navigationButton(.overview, title: "Aktionen")
#endif

#if !ADMIN_APP
            Button {
                showBillboard = true
            } label: {
                Label("Billboard Vollbild", systemImage: "rectangle.inset.filled")
            }
            .buttonStyle(SidebarButtonStyle())
#endif

            Divider().background(Color.white.opacity(0.3))

            Button {
                logout()
            } label: {
                Label("Admin Logout", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(LogoutButtonStyle(compact: isCompact))

            if !isCompact {
                Spacer()
            }

            HStack {
                Spacer()
                partnerLogos
            }
        }
        .padding(isCompact ? 16 : 22)
        .frame(width: isCompact ? nil : 260)
        .frame(maxWidth: isCompact ? .infinity : nil)
        .background(SecretMatchTheme.surface.opacity(0.97))
        .overlay(alignment: isCompact ? .bottom : .trailing) {
            Rectangle()
                .fill(SecretMatchTheme.border)
                .frame(width: isCompact ? nil : 1, height: isCompact ? 1 : nil)
        }
    }

    @ViewBuilder
    private var partnerLogos: some View {
        let managedItems = api.screensaverItems.filter { $0.enabled && $0.showAsSponsor }
        if managedItems.isEmpty {
            HStack(alignment: .center, spacing: 5) {
                    Image("hot-chili")
                        .resizable()
                        .scaledToFit()
                        .frame(width: isCompact ? 64 : 48, height: isCompact ? 48 : 38)
                        .accessibilityLabel("Hot Chili Events")

                    Image("ficken-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: isCompact ? 68 : 54, height: isCompact ? 38 : 30)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.94))
                        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
                        .accessibilityLabel("FICKEN Likör")

                    Image("club2020")
                        .resizable()
                        .scaledToFit()
                        .frame(width: isCompact ? 108 : 88, height: isCompact ? 74 : 62)
                        .accessibilityLabel("Club 2020")
            }
        } else {
            TimelineView(.periodic(from: .now, by: 6)) { context in
                let index = Int(context.date.timeIntervalSince1970 / 6) % managedItems.count
                let item = managedItems[index]
                if let image = api.cachedScreensaverImage(for: item) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: isCompact ? 210 : 180, maxHeight: isCompact ? 74 : 62)
                        .managedMediaBackdrop(
                            item.useLightBackground,
                            insets: EdgeInsets(top: 4, leading: 7, bottom: 4, trailing: 7)
                        )
                        .accessibilityLabel(item.title.isEmpty ? "Sponsorbild" : item.title)
                }
            }
        }
    }

    private func navigationButton(_ section: AdminDashboardSection, title: String? = nil) -> some View {
        Button {
            dashboardSection = section
            dismissMenu()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: section.systemImage)
                    .foregroundStyle(section.tint)
                    .frame(width: 24)
                Text(title ?? section.title)
                Spacer(minLength: 0)
                if dashboardSection == section {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(section.tint)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(SidebarButtonStyle(
            compact: isCompact,
            isSelected: dashboardSection == section,
            tint: section.tint
        ))
        .accessibilityAddTraits(dashboardSection == section ? .isSelected : [])
    }
}
