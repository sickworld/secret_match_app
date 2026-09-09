import Foundation
import SwiftUI
import UIKit

struct ScreensaverMediaItem: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let attachmentID: Int?
    let title: String
    let imageURL: String
    let showInScreensaver: Bool
    let showAsSponsor: Bool
    let useLightBackground: Bool
    let displaySeconds: Int
    let enabled: Bool
    let sortOrder: Int
    let revision: Int
    let updatedAt: Int?

    var remoteURL: URL? { URL(string: imageURL) }

    private enum CodingKeys: String, CodingKey {
        case id
        case attachmentID = "attachment_id"
        case title
        case imageURL = "image_url"
        case showInScreensaver = "show_in_screensaver"
        case showAsSponsor = "show_as_sponsor"
        case useLightBackground = "use_light_background"
        case displaySeconds = "display_seconds"
        case enabled
        case sortOrder = "sort_order"
        case revision
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        attachmentID = try values.decodeIfPresent(Int.self, forKey: .attachmentID)
        title = try values.decode(String.self, forKey: .title)
        imageURL = try values.decode(String.self, forKey: .imageURL)
        showInScreensaver = try values.decode(Bool.self, forKey: .showInScreensaver)
        showAsSponsor = try values.decode(Bool.self, forKey: .showAsSponsor)
        useLightBackground = try values.decodeIfPresent(Bool.self, forKey: .useLightBackground) ?? false
        displaySeconds = try values.decode(Int.self, forKey: .displaySeconds)
        enabled = try values.decode(Bool.self, forKey: .enabled)
        sortOrder = try values.decode(Int.self, forKey: .sortOrder)
        revision = try values.decode(Int.self, forKey: .revision)
        updatedAt = try values.decodeIfPresent(Int.self, forKey: .updatedAt)
    }
}

struct ScreensaverSettingsResponse: Codable, Equatable, Sendable {
    let idleSeconds: Int

    private enum CodingKeys: String, CodingKey {
        case idleSeconds = "idle_seconds"
    }
}

private struct ManagedMediaBackdropModifier: ViewModifier {
    let enabled: Bool
    let insets: EdgeInsets

    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled {
            content
                .padding(insets)
                .background(Color.white.opacity(0.96))
                .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
        } else {
            content
        }
    }
}

extension View {
    func managedMediaBackdrop(
        _ enabled: Bool,
        insets: EdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    ) -> some View {
        modifier(ManagedMediaBackdropModifier(enabled: enabled, insets: insets))
    }
}

enum ScreensaverMediaCache {
    private static let catalogKey = "secretmatch.screensaver-media-catalog.v1"
    private static let idleSecondsKey = "secretmatch.screensaver-idle-seconds.v1"

    static func loadIdleSeconds() -> Int {
        guard UserDefaults.standard.object(forKey: idleSecondsKey) != nil else { return 60 }
        return max(15, min(600, UserDefaults.standard.integer(forKey: idleSecondsKey)))
    }

    static func storeIdleSeconds(_ seconds: Int) {
        UserDefaults.standard.set(max(15, min(600, seconds)), forKey: idleSecondsKey)
    }

    static func loadCatalog() -> [ScreensaverMediaItem] {
        guard let data = UserDefaults.standard.data(forKey: catalogKey),
              let items = try? JSONDecoder().decode([ScreensaverMediaItem].self, from: data),
              items.allSatisfy({ image(for: $0) != nil }) else {
            return []
        }
        return items
    }

    static func image(for item: ScreensaverMediaItem) -> UIImage? {
        guard let url = cachedImageURL(for: item) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    static func containsImage(for item: ScreensaverMediaItem) -> Bool {
        image(for: item) != nil
    }

    static func storeCompleteCatalog(
        _ items: [ScreensaverMediaItem],
        downloadedData: [String: Data]
    ) throws {
        let directory = try cacheDirectory()
        for item in items {
            guard let destination = cachedImageURL(for: item, directory: directory) else {
                throw CocoaError(.fileWriteInvalidFileName)
            }
            if let data = downloadedData[item.id] {
                try data.write(to: destination, options: .atomic)
            }
            guard UIImage(contentsOfFile: destination.path) != nil else {
                throw CocoaError(.fileReadCorruptFile)
            }
        }

        let catalogData = try JSONEncoder().encode(items)
        UserDefaults.standard.set(catalogData, forKey: catalogKey)

        let expectedFiles = Set(items.compactMap { cachedImageURL(for: $0, directory: directory)?.lastPathComponent })
        let cachedFiles = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )) ?? []
        for file in cachedFiles where !expectedFiles.contains(file.lastPathComponent) {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private static func cachedImageURL(for item: ScreensaverMediaItem, directory: URL? = nil) -> URL? {
        let safeID = item.id.lowercased().filter { $0.isHexDigit || $0 == "-" }
        guard safeID.count == 36 else { return nil }
        let base = directory ?? (try? cacheDirectory())
        return base?.appendingPathComponent("\(safeID)-\(max(1, item.revision)).image", isDirectory: false)
    }

    private static func cacheDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent("MatchAndPlayScreensaver", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
