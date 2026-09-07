import SwiftUI

struct AdminMatchRequestListView: View {
    @EnvironmentObject private var api: APIService
    @Binding var isPresented: Bool
    var isEmbedded = false

    @State private var searchText = ""
    @State private var selectedType = "all"
    @State private var selectedStatus = "all"
    @State private var pendingDelete: AdminMatchRequest?
    @State private var editingRequest: AdminMatchRequest?
    @State private var loadErrorMessage: String?
    @State private var operationErrorMessage: String?

    var body: some View {
        ZStack {
            if !isEmbedded {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture { isPresented = false }
            }

            VStack(spacing: 18) {
                header

                if let operationErrorMessage {
                    Label(operationErrorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                filters

                if let loadErrorMessage {
                    loadErrorState(message: loadErrorMessage)
                } else if filteredRequests.isEmpty {
                    ContentUnavailableView(
                        api.adminMatchRequests.isEmpty ? "Keine Match-Requests" : "Keine Treffer",
                        systemImage: "heart.text.square",
                        description: Text(api.adminMatchRequests.isEmpty
                            ? "Gesendete Match-Wünsche erscheinen hier."
                            : "Suche oder Filter anpassen.")
                    )
                    .foregroundStyle(.white)
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 14)], spacing: 14) {
                            ForEach(filteredRequests) { request in
                                requestRow(request)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .refreshable { await loadRequests() }
                }
            }
            .frame(maxWidth: 1040, maxHeight: isEmbedded ? .infinity : 780)
            .secretCard(cornerRadius: 26, padding: 26)
            .padding(24)
        }
        .task { await loadRequests() }
        .alert("Match-Request löschen?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) {
                guard let request = pendingDelete else { return }
                pendingDelete = nil
                Task { await delete(request) }
            }
        } message: {
            Text("Der Request wird dauerhaft entfernt. Ein bereits entstandener Match bleibt bestehen.")
        }
        .sheet(item: $editingRequest) { request in
            AdminMatchRequestEditorView(request: request) { participantA, participantB, type, message in
                try await api.updateAdminMatchRequest(
                    id: request.id,
                    participantA: participantA,
                    participantB: participantB,
                    type: type,
                    message: message
                )
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("EVENT CONTROL · \(filteredRequests.count) EINTRÄGE")
                    .font(.caption.bold())
                    .tracking(1.8)
                    .foregroundStyle(SecretMatchTheme.secondary)
                Text("Match-Requests verwalten")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer()
            if !isEmbedded {
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.title3.bold())
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.white)
                        .background(SecretMatchTheme.surfaceRaised)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Match-Requests schließen")
            }
        }
    }

    private var filters: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { searchField; typePicker; statusPicker }
            VStack(spacing: 12) {
                searchField
                HStack(spacing: 12) { typePicker; statusPicker }
            }
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(SecretMatchTheme.muted)
            TextField("Absender oder Empfänger suchen", text: $searchText)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .frame(minWidth: 240, maxWidth: .infinity, minHeight: 54)
        .background(Color.black.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var typePicker: some View {
        Picker("Typ", selection: $selectedType) {
            Text("Alle Typen").tag("all")
            Text("❤️ Hot").tag("normal")
            Text("🍆 Fuck").tag("hot")
        }
        .pickerStyle(.menu)
        .tint(.white)
        .frame(minWidth: 130, minHeight: 54)
        .background(SecretMatchTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var statusPicker: some View {
        Picker("Status", selection: $selectedStatus) {
            Text("Alle Status").tag("all")
            Text("Offen").tag("open")
            Text("Gematcht").tag("matched")
        }
        .pickerStyle(.menu)
        .tint(.white)
        .frame(minWidth: 130, minHeight: 54)
        .background(SecretMatchTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func loadErrorState(message: String) -> some View {
        ContentUnavailableView {
            Label("Match-Requests konnten nicht geladen werden", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Erneut versuchen") { Task { await loadRequests() } }
                .buttonStyle(SecretPrimaryButtonStyle(fullWidth: false))
        }
        .foregroundStyle(.white)
        .frame(maxHeight: .infinity)
    }

    private func requestRow(_ request: AdminMatchRequest) -> some View {
        let color = request.type == "hot" ? Color(hex: "#8E63D2") : Color(hex: "#E83E8C")

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                Text(request.type == "hot" ? "🍆" : "❤️")
                    .font(.system(size: 30))
                    .frame(width: 54, height: 54)
                    .background(color.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 6) {
                    Text(request.type == "hot" ? "Fuck-Request" : "Hot-Request")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(request.participantA.displayEventNumber) → \(request.participantB.displayEventNumber)")
                        .font(.system(size: 19, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(SecretMatchTheme.muted)
                    statusBadge(request.isMatched)
                }

                Spacer(minLength: 0)
            }

            if !request.message.isEmpty {
                Text(request.message)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.black.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            HStack {
                Spacer()
                Button { editingRequest = request } label: {
                    Label("Bearbeiten", systemImage: "pencil")
                        .font(.callout.bold())
                        .foregroundStyle(SecretMatchTheme.secondary)
                        .padding(10)
                }
                .accessibilityLabel("Match-Request bearbeiten")

                Button(role: .destructive) { pendingDelete = request } label: {
                    Image(systemName: "trash")
                        .font(.title3.bold())
                        .foregroundStyle(.red)
                        .padding(10)
                }
                .accessibilityLabel("Match-Request löschen")
            }
        }
        .padding()
        .background(color.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.65), lineWidth: 1.2))
    }

    private func statusBadge(_ isMatched: Bool) -> some View {
        Text(isMatched ? "GEMATCHT" : "OFFEN")
            .font(.caption2.bold())
            .foregroundStyle(isMatched ? Color.green : SecretMatchTheme.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((isMatched ? Color.green : SecretMatchTheme.secondary).opacity(0.16))
            .clipShape(Capsule())
    }

    private var filteredRequests: [AdminMatchRequest] {
        api.adminMatchRequests.filter { request in
            let matchesType = selectedType == "all" || request.type == selectedType
            let matchesStatus = selectedStatus == "all"
                || (selectedStatus == "matched" && request.isMatched)
                || (selectedStatus == "open" && !request.isMatched)
            let matchesSearch = searchText.isEmpty
                || request.participantA.localizedCaseInsensitiveContains(searchText)
                || request.participantB.localizedCaseInsensitiveContains(searchText)
                || request.participantA.displayEventNumber.localizedCaseInsensitiveContains(searchText)
                || request.participantB.displayEventNumber.localizedCaseInsensitiveContains(searchText)
            return matchesType && matchesStatus && matchesSearch
        }
    }

    @MainActor
    private func loadRequests() async {
        loadErrorMessage = nil
        do {
            try await api.loadAdminMatchRequests()
        } catch {
            loadErrorMessage = "Bitte Admin-Anmeldung und Netzwerkverbindung prüfen."
        }
    }

    @MainActor
    private func delete(_ request: AdminMatchRequest) async {
        operationErrorMessage = nil
        do {
            try await api.deleteAdminMatchRequest(id: request.id)
        } catch {
            operationErrorMessage = "Match-Request konnte nicht gelöscht werden: \(error.localizedDescription)"
        }
    }
}

private struct AdminMatchRequestEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let request: AdminMatchRequest
    let onSave: (String, String, String, String) async throws -> Void

    @State private var participantA: String
    @State private var participantB: String
    @State private var type: String
    @State private var message: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        request: AdminMatchRequest,
        onSave: @escaping (String, String, String, String) async throws -> Void
    ) {
        self.request = request
        self.onSave = onSave
        _participantA = State(initialValue: request.participantA.displayEventNumber)
        _participantB = State(initialValue: request.participantB.displayEventNumber)
        _type = State(initialValue: request.type)
        _message = State(initialValue: request.message)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Teilnehmernummern") {
                    TextField("Absender", text: $participantA)
                        .keyboardType(.numberPad)
                    TextField("Empfänger", text: $participantB)
                        .keyboardType(.numberPad)
                    if sameNumber {
                        Label("Absender und Empfänger müssen unterschiedlich sein.", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }

                Section("Typ") {
                    Picker("Typ", selection: $type) {
                        Text("❤️ Hot Match").tag("normal")
                        Text("🍆 Fuck Match").tag("hot")
                    }
                    .pickerStyle(.inline)
                }

                Section("Freitext") {
                    TextEditor(text: $message)
                        .frame(minHeight: 90)
                        .onChange(of: message) { _, value in
                            if value.count > 180 {
                                message = String(value.prefix(180))
                            }
                        }
                    Text("\(message.count)/180")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Section {
                    Text("Änderungen am Request verändern einen bereits entstandenen Match nicht.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Match-Request bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(isSaving)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving { ProgressView() } else { Text("Speichern") }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }

    private var participantANormalized: String { participantA.normalizedEventNumber }
    private var participantBNormalized: String { participantB.normalizedEventNumber }
    private var sameNumber: Bool {
        !participantANormalized.isEmpty && participantANormalized == participantBNormalized
    }
    private var isValid: Bool {
        isValidNumber(participantA)
            && isValidNumber(participantB)
            && !sameNumber
            && ["normal", "hot"].contains(type)
            && message.count <= 180
    }

    private func isValidNumber(_ value: String) -> Bool {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        return !cleaned.isEmpty
            && cleaned.count <= 10
            && cleaned.allSatisfy(\.isNumber)
            && cleaned.normalizedEventNumber != "0"
    }

    @MainActor
    private func save() async {
        guard isValid else { return }
        isSaving = true
        errorMessage = nil
        do {
            try await onSave(participantANormalized, participantBNormalized, type, message)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }
}
