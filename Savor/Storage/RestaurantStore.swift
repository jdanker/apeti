//
//  RestaurantStore.swift
//  Savor
//
//  Created by Jahred Danker on 9/20/25.
//

import Foundation

final class RestaurantStore {
    private let fileUrl: URL
    // Lists live in their own file rather than one combined document so existing
    // restaurants.json saves decode untouched — no migration needed.
    private let listsFileUrl: URL
    private let directory: URL

    // Injectable directory so tests can point at a temp dir instead of the real
    // app container; production callers take the Documents default.
    init(directory: URL? = nil) {
        let dir = directory ?? FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        self.directory = dir
        fileUrl = dir.appendingPathComponent("restaurants.json")
        listsFileUrl = dir.appendingPathComponent("lists.json")
    }

    #if DEBUG
        // Exposed for tests that verify quarantine files land next to the data.
        var directoryForTesting: URL? { directory }
    #endif

    func load() -> [Restaurant] {
        loadArray(from: fileUrl)
    }

    func save(_ restaurants: [Restaurant]) {
        saveArray(restaurants, to: fileUrl)
    }

    func loadLists() -> [RestaurantList] {
        loadArray(from: listsFileUrl)
    }

    func saveLists(_ lists: [RestaurantList]) {
        saveArray(lists, to: listsFileUrl)
    }

    // MARK: - Shared persistence plumbing

    private func loadArray<T: Decodable>(from url: URL) -> [T] {
        // Missing file is the normal first-launch case — distinct from corruption.
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([T].self, from: data)
        } catch {
            // A file exists but can't be read: returning [] alone would be a
            // time bomb — the next autosave would overwrite the user's only
            // copy with an empty array. Move it aside first so the data
            // survives for recovery by a fixed build.
            quarantine(url)
            print("Load failed for \(url.lastPathComponent), file quarantined: \(error)")
            return []
        }
    }

    private func saveArray<T: Encodable>(_ items: [T], to url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(items)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Save failed for \(url.lastPathComponent): \(error)")
        }
    }

    private func quarantine(_ url: URL) {
        // Timestamped name so repeated failures never clobber an earlier backup.
        let backup = url.appendingPathExtension(
            "corrupt-\(Int(Date().timeIntervalSince1970))"
        )
        try? FileManager.default.moveItem(at: url, to: backup)
    }
}
