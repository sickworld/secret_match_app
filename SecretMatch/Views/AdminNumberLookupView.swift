import SwiftUI

struct AdminNumberLookupView: View {
    @EnvironmentObject private var api: APIService
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var overview: AdminNumberOverview?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    searchCard

                    if isLoading {
                        ProgressView("Nummer wird gesucht …")
                            .tint(SecretMatchTheme.secondary)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 220)
                    } else if let errorMessage {
                        ContentUnavailableView {
                            Label("Nummer nicht abrufbar", systemImage: "magnifyingglass")
                        } description: {
                            Text(errorMessage)
                        } actions: {
                            Button("Erneut versuchen") { Task { await search() } }
                        }
                        .foregroundStyle(.white)
                    } else if let overview {
                        resultContent(overview)
                    } else {
                        ContentUnavailableView(
                            "Eventnummer suchen",
                            systemImage: "person.text.rectangle",
                            description: Text("Zeigt Status, Interaktionen, Geräte und die letzten Protokolle einer Nummer an.")
                        )
                        .foregroundStyle(.white)
                        .frame(minHeight: 260)
                    }
                }
                .padding(24)
                .frame(maxWidth: 1000)
                .frame(maxWidth: .infinity)
            }
            .background(BrandBackground())
            .navigationTitle("Globale Nummernsuche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
    }

    private var searchCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.title2.bold())
                .foregroundStyle(SecretMatchTheme.secondary)
            TextField("Eventnummer", text: $query)
                .font(.title2.bold().monospacedDigit())
                .keyboardType(.numberPad)
                .textContentType(.none)
                .foregroundStyle(.white)
                .onSubmit { Task { await search() } }
            Button("Suchen") { Task { await search() } }
                .buttonStyle(.borderedProminent)
                .tint(SecretMatchTheme.primary)
                .disabled(query.normalizedEventNumber.isEmpty || isLoading)
        }
        .padding(16)
        .secretCard(cornerRadius: 18, padding: 0)
    }

    @ViewBuilder
    private func resultContent(_ overview: AdminNumberOverview) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(overview.number.displayEventNumber)
                .font(.system(size: 42, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
            Spacer()
            Label(overview.active ? "Gerade aktiv" : "Nicht aktiv", systemImage: overview.active ? "circle.fill" : "circle")
                .font(.subheadline.bold())
                .foregroundStyle(overview.active ? .green : SecretMatchTheme.muted)
        }

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
            statusCard("Freigegeben", value: overview.allowed ? "Ja" : "Nein", icon: "person.badge.key.fill", color: overview.allowed ? .green : .red)
            statusCard("PIN", value: overview.pinConfigured ? "Eingerichtet" : "Fehlt", icon: "lock.fill", color: overview.pinConfigured ? .green : .orange)
            statusCard("Gender", value: genderLabel(overview.gender), icon: "person.crop.circle", color: overview.gender == nil ? .orange : SecretMatchTheme.secondary)
            statusCard("Geräte", value: "\(overview.devices.count)", icon: "ipad", color: overview.devices.isEmpty ? SecretMatchTheme.muted : .green)
        }

        section("Aktivität", icon: "chart.bar.fill") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 10)], spacing: 10) {
                metric("Requests gesendet", overview.counts.sentRequests)
                metric("Requests erhalten", overview.counts.receivedRequests)
                metric("Aktionen gesendet", overview.counts.sentActions)
                metric("Aktionen erhalten", overview.counts.receivedActions)
                metric("Matches", overview.counts.matches)
            }
        }

        if !overview.devices.isEmpty {
            section("Verbundene iPads", icon: "ipad.and.iphone") {
                VStack(spacing: 10) {
                    ForEach(overview.devices) { device in
                        HStack(spacing: 12) {
                            Circle().fill(device.isOnline ? Color.green : Color.red).frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(device.name ?? "iPad").font(.headline).foregroundStyle(.white)
                                Text("\(device.lastSeenDescription) · Akku \(device.batteryLevel) % · Queue \(device.queuedSendCount ?? 0)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(SecretMatchTheme.muted)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }

        section("Letzte Vorgänge", icon: "arrow.left.arrow.right") {
            if overview.recentActivity.isEmpty {
                Text("Für diese Nummer gibt es noch keine Aktionen, Requests oder Matches.")
                    .foregroundStyle(SecretMatchTheme.muted)
            } else {
                VStack(spacing: 0) {
                    ForEach(overview.recentActivity) { activity in
                        HStack(spacing: 12) {
                            Image(systemName: activityIcon(activity.kind))
                                .foregroundStyle(activityColor(activity.kind))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(activityTitle(activity))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                Text("Mit \(activity.counterpart.displayEventNumber) · \(activity.createdAt)")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(SecretMatchTheme.muted)
                            }
                            Spacer()
                            if activity.hasMessage {
                                Image(systemName: "text.bubble.fill")
                                    .foregroundStyle(SecretMatchTheme.secondary)
                                    .accessibilityLabel("Mit Freitext")
                            }
                        }
                        .padding(.vertical, 10)
                        if activity.id != overview.recentActivity.last?.id {
                            Divider().overlay(SecretMatchTheme.border)
                        }
                    }
                }
            }
        }

        section("Letzte Protokolle", icon: "list.bullet.rectangle") {
            if overview.recentLogs.isEmpty {
                Text("Keine Protokolle für diese Nummer gefunden.")
                    .foregroundStyle(SecretMatchTheme.muted)
            } else {
                VStack(spacing: 10) {
                    ForEach(overview.recentLogs.prefix(12)) { entry in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(entry.severity == "error" || entry.severity == "critical" ? Color.red : Color.green)
                                .frame(width: 8, height: 8)
                                .padding(.top, 6)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.title).font(.subheadline.bold()).foregroundStyle(.white)
                                Text(entry.occurredAt).font(.caption).foregroundStyle(SecretMatchTheme.muted)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private func section<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon).font(.title3.bold()).foregroundStyle(.white)
            content()
        }
        .secretCard(cornerRadius: 18, padding: 16)
    }

    private func statusCard(_ title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.headline.bold()).foregroundStyle(.white)
            Text(title).font(.caption.bold()).foregroundStyle(SecretMatchTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .secretCard(cornerRadius: 16, padding: 14)
    }

    private func metric(_ title: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(value)").font(.title2.bold().monospacedDigit()).foregroundStyle(.white)
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(SecretMatchTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(SecretMatchTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 13))
    }

    private func activityTitle(_ activity: AdminNumberActivity) -> String {
        let type = typeLabel(activity.type)
        switch activity.kind {
        case "match": return "\(type)-Match"
        case "request": return activity.direction == "sent" ? "\(type)-Request gesendet" : "\(type)-Request erhalten"
        default: return activity.direction == "sent" ? "\(type) gesendet" : "\(type) erhalten"
        }
    }

    private func activityIcon(_ kind: String) -> String {
        kind == "match" ? "sparkles" : (kind == "request" ? "heart.text.square.fill" : "paperplane.fill")
    }

    private func activityColor(_ kind: String) -> Color {
        kind == "match" ? .green : (kind == "request" ? SecretMatchTheme.primary : SecretMatchTheme.secondary)
    }

    private func typeLabel(_ type: String) -> String {
        ["normal": "Hot", "hot": "Fuck", "bjob": "Blow-Job", "hjob": "Hand-Job", "ljob": "Lick-Job"][type] ?? type
    }

    private func genderLabel(_ gender: String?) -> String {
        switch gender {
        case "female": return "Weiblich"
        case "male": return "Männlich"
        case "skip": return "Lieber nicht"
        default: return "Nicht angegeben"
        }
    }

    private func search() async {
        guard !query.normalizedEventNumber.isEmpty, !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            overview = try await api.loadAdminNumberOverview(number: query)
        } catch {
            overview = nil
            errorMessage = "Die Nummer konnte nicht geladen werden. Bitte Verbindung und Eingabe prüfen."
        }
        isLoading = false
    }
}
