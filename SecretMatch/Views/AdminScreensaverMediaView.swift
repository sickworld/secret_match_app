import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct AdminScreensaverMediaView: View {
    @EnvironmentObject private var api: APIService
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var showInScreensaver = true
    @State private var showAsSponsor = true
    @State private var useLightBackground = false
    @State private var displaySeconds = 6
    @State private var enabled = true
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showFileImporter = false
    @State private var editingItem: ScreensaverMediaItem?
    @State private var deletingItem: ScreensaverMediaItem?
    @State private var editTitle = ""
    @State private var editShowInScreensaver = true
    @State private var editShowAsSponsor = true
    @State private var editUseLightBackground = false
    @State private var editDisplaySeconds = 6
    @State private var editEnabled = true
    @State private var editSortOrder = 0
    @State private var editErrorMessage: String?
    @State private var isWorking = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    feedback
                    existingItems
                    addItem
                }
                .padding(20)
                .frame(maxWidth: 980)
                .frame(maxWidth: .infinity)
            }
            .background(BrandBackground())
            .navigationTitle("Bildschirmschoner & Sponsoren")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { await loadItems() }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task { await loadPhoto(item) }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.image]) { result in
            loadImportedFile(result)
        }
        .sheet(item: $editingItem) { _ in
            editSheet
        }
        .alert("Bild entfernen?", isPresented: Binding(
            get: { deletingItem != nil },
            set: { if !$0 { deletingItem = nil } }
        )) {
            Button("Abbrechen", role: .cancel) {}
            Button("Entfernen", role: .destructive) {
                guard let item = deletingItem else { return }
                deletingItem = nil
                Task { await delete(item) }
            }
        } message: {
            Text("Der Eintrag verschwindet von den iPads. Die Originaldatei bleibt in der WordPress-Mediathek erhalten.")
        }
    }

    @ViewBuilder
    private var feedback: some View {
        if let statusMessage {
            Label(statusMessage, systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.callout.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .secretCard(padding: 14)
        }
        if let errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.callout.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .secretCard(padding: 14)
        }
    }

    private var existingItems: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Medienkatalog")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Die Reihenfolge gilt für Bildschirmschoner und Sponsorleiste.")
                    .foregroundStyle(SecretMatchTheme.muted)
            }

            if api.adminScreensaverItems.isEmpty {
                Text("Noch keine eigenen Bilder. Die iPads zeigen weiterhin die mitgelieferten Standardbilder.")
                    .foregroundStyle(SecretMatchTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .secretCard(padding: 18)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 14)], spacing: 14) {
                    ForEach(api.adminScreensaverItems) { item in
                        mediaCard(item)
                    }
                }
            }
        }
    }

    private func mediaCard(_ item: ScreensaverMediaItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            mediaPreview(item)
                .frame(maxWidth: .infinity)
                .managedMediaBackdrop(
                    item.useLightBackground,
                    insets: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
                )
                .frame(height: 150)
                .background(SecretMatchTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))

            Text(item.title)
                .font(.headline.bold())
                .foregroundStyle(.white)
                .lineLimit(2)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 76), alignment: .leading)],
                alignment: .leading,
                spacing: 7
            ) {
                if item.enabled {
                    statusChip("Aktiv", icon: "checkmark.circle.fill", color: .green)
                } else {
                    statusChip("Pausiert", icon: "pause.circle.fill", color: .orange)
                }
                if item.showInScreensaver {
                    statusChip("Schoner", icon: "sparkles.rectangle.stack", color: SecretMatchTheme.primary)
                }
                if item.showAsSponsor {
                    statusChip("Sponsor", icon: "rectangle.bottomthird.inset.filled", color: SecretMatchTheme.secondary)
                }
                if item.useLightBackground {
                    statusChip("Hell", icon: "sun.max.fill", color: .yellow)
                }
            }

            Text("Position \(item.sortOrder) · \(item.displaySeconds) Sekunden")
                .font(.caption.monospacedDigit())
                .foregroundStyle(SecretMatchTheme.muted)

            HStack(spacing: 10) {
                Button("Bearbeiten") { beginEditing(item) }
                    .buttonStyle(SecretSecondaryButtonStyle())
                Button(role: .destructive) { deletingItem = item } label: {
                    Image(systemName: "trash.fill")
                        .frame(minWidth: 30)
                }
                .buttonStyle(SecretSecondaryButtonStyle())
                .accessibilityLabel("\(item.title) entfernen")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .secretCard(padding: 16)
    }

    private var addItem: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Neues Bild")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Fotos werden vor dem Upload auf eine eventtaugliche Größe verkleinert und als JPG gespeichert.")
                .foregroundStyle(SecretMatchTheme.muted)

            if let selectedImageData, let image = UIImage(data: selectedImageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .managedMediaBackdrop(
                        useLightBackground,
                        insets: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
                    )
                    .frame(height: 180)
                    .background(SecretMatchTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
            }

            HStack(spacing: 10) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label(selectedImageData == nil ? "Foto wählen" : "Anderes Foto", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(SecretSecondaryButtonStyle())

                Button {
                    showFileImporter = true
                } label: {
                    Label("Datei wählen", systemImage: "folder")
                }
                .buttonStyle(SecretSecondaryButtonStyle())
            }

            AdminKeyboardTextField(
                title: "Begleittext",
                text: $title,
                keyboard: .text(maxCharacters: 100),
                keyboardTitle: "Begleittext"
            )
            .textFieldStyle(.plain)
            .secretAdminInput()

            mediaSettings(
                showInScreensaver: $showInScreensaver,
                showAsSponsor: $showAsSponsor,
                useLightBackground: $useLightBackground,
                displaySeconds: $displaySeconds,
                enabled: $enabled
            )

            Button {
                Task { await upload() }
            } label: {
                if isWorking {
                    ProgressView().tint(.white)
                } else {
                    Label("Bild hinzufügen", systemImage: "square.and.arrow.up.fill")
                }
            }
            .buttonStyle(SecretPrimaryButtonStyle())
            .disabled(isWorking || selectedImageData == nil || (enabled && !showInScreensaver && !showAsSponsor))
        }
        .secretCard(padding: 20)
    }

    private var editSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let editErrorMessage {
                        Label(editErrorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.callout.bold())
                            .foregroundStyle(.red)
                    }

                    if let editingItem {
                        mediaPreview(editingItem)
                            .frame(maxWidth: .infinity)
                            .managedMediaBackdrop(
                                editUseLightBackground,
                                insets: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
                            )
                            .frame(height: 180)
                            .background(SecretMatchTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
                    }

                    AdminKeyboardTextField(
                        title: "Begleittext",
                        text: $editTitle,
                        keyboard: .text(maxCharacters: 100),
                        keyboardTitle: "Begleittext"
                    )
                    .textFieldStyle(.plain)
                    .secretAdminInput()

                    mediaSettings(
                        showInScreensaver: $editShowInScreensaver,
                        showAsSponsor: $editShowAsSponsor,
                        useLightBackground: $editUseLightBackground,
                        displaySeconds: $editDisplaySeconds,
                        enabled: $editEnabled
                    )

                    Stepper("Position \(editSortOrder)", value: $editSortOrder, in: 0...999)
                        .foregroundStyle(.white)

                    Button {
                        Task { await saveEdit() }
                    } label: {
                        if isWorking {
                            ProgressView().tint(.white)
                        } else {
                            Label("Änderungen speichern", systemImage: "square.and.arrow.down.fill")
                        }
                    }
                    .buttonStyle(SecretPrimaryButtonStyle())
                    .disabled(isWorking || (editEnabled && !editShowInScreensaver && !editShowAsSponsor))
                }
                .padding(20)
            }
            .background(BrandBackground())
            .navigationTitle("Bild bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { editingItem = nil }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func mediaSettings(
        showInScreensaver: Binding<Bool>,
        showAsSponsor: Binding<Bool>,
        useLightBackground: Binding<Bool>,
        displaySeconds: Binding<Int>,
        enabled: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Aktiv", isOn: enabled)
            Toggle("Im Bildschirmschoner", isOn: showInScreensaver)
            Toggle("In der Sponsorleiste", isOn: showAsSponsor)
            Toggle("Heller Hintergrund", isOn: useLightBackground)
            Text("Für dunkle oder schwarze Logos auf dem dunklen App-Hintergrund.")
                .font(.caption)
                .foregroundStyle(SecretMatchTheme.muted)
            Stepper("Je Bild \(displaySeconds.wrappedValue) Sekunden", value: displaySeconds, in: 3...30)
        }
        .foregroundStyle(.white)
        .tint(SecretMatchTheme.primary)
    }

    @ViewBuilder
    private func mediaPreview(_ item: ScreensaverMediaItem) -> some View {
        if let cached = api.cachedScreensaverImage(for: item) {
            Image(uiImage: cached)
                .resizable()
                .scaledToFit()
        } else if let url = item.remoteURL {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFit()
                } else if phase.error != nil {
                    Label("Bild nicht verfügbar", systemImage: "photo.badge.exclamationmark")
                        .foregroundStyle(SecretMatchTheme.muted)
                } else {
                    ProgressView().tint(.white)
                }
            }
        } else {
            Label("Bild fehlt", systemImage: "photo.badge.exclamationmark")
                .foregroundStyle(SecretMatchTheme.muted)
        }
    }

    private func statusChip(_ title: String, icon: String, color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func beginEditing(_ item: ScreensaverMediaItem) {
        editTitle = item.title
        editShowInScreensaver = item.showInScreensaver
        editShowAsSponsor = item.showAsSponsor
        editUseLightBackground = item.useLightBackground
        editDisplaySeconds = item.displaySeconds
        editEnabled = item.enabled
        editSortOrder = item.sortOrder
        editErrorMessage = nil
        editingItem = item
    }

    @MainActor
    private func loadItems() async {
        do {
            try await api.loadAdminScreensaverContent()
            errorMessage = nil
        } catch {
            errorMessage = "Medien konnten nicht geladen werden."
        }
    }

    @MainActor
    private func loadPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let prepared = Self.preparedJPEG(from: data) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            selectedImageData = prepared
            errorMessage = nil
        } catch {
            errorMessage = "Das Foto konnte nicht vorbereitet werden."
        }
    }

    private func loadImportedFile(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            guard let prepared = Self.preparedJPEG(from: data) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            selectedImageData = prepared
            errorMessage = nil
        } catch {
            errorMessage = "Die Bilddatei konnte nicht gelesen werden."
        }
    }

    @MainActor
    private func upload() async {
        guard let selectedImageData else { return }
        isWorking = true
        statusMessage = nil
        do {
            try await api.uploadAdminScreensaverImage(
                imageData: selectedImageData,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                showInScreensaver: showInScreensaver,
                showAsSponsor: showAsSponsor,
                useLightBackground: useLightBackground,
                displaySeconds: displaySeconds,
                enabled: enabled,
                sortOrder: min(999, (api.adminScreensaverItems.map(\.sortOrder).max() ?? -1) + 1)
            )
            self.selectedImageData = nil
            selectedPhoto = nil
            title = ""
            useLightBackground = false
            displaySeconds = 6
            statusMessage = "Bild wurde gespeichert und wird an die iPads verteilt."
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isWorking = false
    }

    @MainActor
    private func saveEdit() async {
        guard let editingItem else { return }
        isWorking = true
        do {
            try await api.updateAdminScreensaverItem(
                id: editingItem.id,
                title: editTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                showInScreensaver: editShowInScreensaver,
                showAsSponsor: editShowAsSponsor,
                useLightBackground: editUseLightBackground,
                displaySeconds: editDisplaySeconds,
                enabled: editEnabled,
                sortOrder: editSortOrder
            )
            self.editingItem = nil
            editErrorMessage = nil
            statusMessage = "Medieneintrag wurde aktualisiert."
            errorMessage = nil
        } catch {
            editErrorMessage = error.localizedDescription
        }
        isWorking = false
    }

    @MainActor
    private func delete(_ item: ScreensaverMediaItem) async {
        isWorking = true
        do {
            try await api.deleteAdminScreensaverItem(id: item.id)
            statusMessage = "Bild wurde aus dem Katalog entfernt."
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isWorking = false
    }

    private static func preparedJPEG(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        guard image.size.width > 0, image.size.height > 0 else { return nil }
        let maxDimension: CGFloat = 2400
        let largestDimension = max(image.size.width, image.size.height)
        let scale = largestDimension > maxDimension ? maxDimension / largestDimension : 1
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: 0.88)
    }
}
