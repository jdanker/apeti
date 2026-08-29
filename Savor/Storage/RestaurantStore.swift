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

    // Injectable directory so tests can point at a temp dir instead of the real
    // app container; production callers take the Documents default.
    init(directory: URL? = nil) {
        let dir = directory ?? FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        fileUrl = dir.appendingPathComponent("restaurants.json")
        listsFileUrl = dir.appendingPathComponent("lists.json")
    }
    func load() -> [Restaurant] {
        do {
            let data = try Data(contentsOf: fileUrl)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Restaurant].self, from: data)
        } catch {
            // File doesn’t exist yet or decode failed
            return []
        }
    }
    
    func save(_ restaurants: [Restaurant]) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(restaurants)
            try data.write(to: fileUrl, options: .atomic)
        } catch {
            print("Save failed: \(error)")
        }
    }

    func loadLists() -> [RestaurantList] {
        do {
            let data = try Data(contentsOf: listsFileUrl)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([RestaurantList].self, from: data)
        } catch {
            // File doesn't exist yet or decode failed
            return []
        }
    }

    func saveLists(_ lists: [RestaurantList]) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(lists)
            try data.write(to: listsFileUrl, options: .atomic)
        } catch {
            print("Lists save failed: \(error)")
        }
    }
}
