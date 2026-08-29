//
//  PersistenceCompatibilityTests.swift
//  SavorTests
//
//  The data-durability gate: an app update must NEVER lose a user's saved data.
//  Each test seeds a store with the byte-frozen output of a shipped version
//  (see PersistenceFixtures.swift) and proves the CURRENT code reads it back
//  losslessly. If one of these fails, the change that broke it cannot ship —
//  fix the model, never the fixture.
//

import Foundation
import Testing

@testable import Savor

/// A store whose directory is pre-seeded with fixture file contents, simulating
/// a user's device right after they've installed an update over old data.
private func makeSeededStore(
    restaurantsJSON: String? = nil,
    listsJSON: String? = nil
) throws -> RestaurantStore {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("savor-compat-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    if let restaurantsJSON {
        try Data(restaurantsJSON.utf8).write(to: dir.appendingPathComponent("restaurants.json"))
    }
    if let listsJSON {
        try Data(listsJSON.utf8).write(to: dir.appendingPathComponent("lists.json"))
    }
    return RestaurantStore(directory: dir)
}

@Suite("Persistence backward compatibility")
struct PersistenceCompatibilityTests {

    // MARK: - Decoding every shipped format

    @Test("v1.0 restaurants decode losslessly")
    func decodeV1_0() throws {
        let store = try makeSeededStore(restaurantsJSON: PersistenceFixtures.restaurantsV1_0)
        let restaurants = store.load()

        // Count first: the store's decode-failed path returns [], so an empty
        // result IS the data-loss bug this suite exists to catch.
        #expect(restaurants.count == 2)

        let pappys = try #require(restaurants.first { $0.name == "Pappy's Smokehouse" })
        #expect(pappys.id == UUID(uuidString: "11111111-AAAA-4AAA-8AAA-111111111111"))
        #expect(pappys.placeID == "fixture.pappys")
        #expect(pappys.rating == 4.7)
        #expect(pappys.types == ["barbecue_restaurant", "restaurant"])
        #expect(pappys.priceLevel == 2)
        #expect(pappys.visitStatus == .been)
        #expect(pappys.addedAt == Date(timeIntervalSince1970: 1_759_343_400))
        // Fields that didn't exist in 1.0 must default to nil, not fail decode
        #expect(pappys.latitude == nil)
        #expect(pappys.websiteURL == nil)

        let balkan = try #require(restaurants.first { $0.name == "Balkan Treat Box" })
        #expect(balkan.priceLevel == nil)
        #expect(balkan.editorialSummary == nil)
        #expect(balkan.visitStatus == .none)
    }

    @Test("v1.1 restaurants (live App Store version) decode losslessly")
    func decodeV1_1() throws {
        let store = try makeSeededStore(restaurantsJSON: PersistenceFixtures.restaurantsV1_1)
        let restaurants = store.load()

        #expect(restaurants.count == 2)

        let loafers = try #require(restaurants.first { $0.placeID == "fixture.union-loafers" })
        #expect(loafers.websiteURL == URL(string: "https://www.unionloafers.com/"))
        #expect(loafers.reviewSummary == "People love the bread.")
        #expect(loafers.lastRefreshedAt != nil)
        #expect(loafers.visitStatus == .been)

        let olio = try #require(restaurants.first { $0.placeID == "fixture.olio" })
        #expect(olio.websiteURL == nil)
        #expect(olio.lastRefreshedAt == nil)
    }

    @Test("v1.2 restaurants and lists decode losslessly")
    func decodeV1_2() throws {
        let store = try makeSeededStore(
            restaurantsJSON: PersistenceFixtures.restaurantsV1_2,
            listsJSON: PersistenceFixtures.listsV1_2
        )

        let restaurants = store.load()
        #expect(restaurants.count == 1)
        let sado = try #require(restaurants.first)
        #expect(sado.latitude == 38.6103)
        #expect(sado.longitude == -90.3123)

        let lists = store.loadLists()
        #expect(lists.count == 2)

        let smart = try #require(lists.first { $0.name == "Coffee Shops" })
        #expect(smart.smartCategory == .coffee)
        #expect(smart.restaurantIDs.count == 2)

        let manual = try #require(lists.first { $0.name == "Date Night" })
        #expect(manual.smartCategory == nil)
        #expect(manual.restaurantIDs == [UUID(uuidString: "55555555-EEEE-4EEE-8EEE-555555555555")!])
    }

    // MARK: - Round-trip: re-saving old data must not drop anything

    @Test("v1.1 data survives a load → save → load cycle intact")
    func roundTripV1_1() throws {
        let store = try makeSeededStore(restaurantsJSON: PersistenceFixtures.restaurantsV1_1)
        let loaded = store.load()
        #expect(loaded.count == 2)

        // Simulates the app's autosave after update: re-encode with current code
        store.save(loaded)
        let reloaded = store.load()

        // Field-for-field equality (synthesized ==) — a silently dropped field fails here
        #expect(reloaded == loaded)
    }

    @Test("v1.2 lists survive a load → save → load cycle intact")
    func roundTripListsV1_2() throws {
        let store = try makeSeededStore(listsJSON: PersistenceFixtures.listsV1_2)
        let loaded = store.loadLists()
        #expect(loaded.count == 2)

        store.saveLists(loaded)
        #expect(store.loadLists() == loaded)
    }

    // MARK: - Forward tolerance: unknown keys must not break decode

    @Test("unknown fields from a newer version are tolerated")
    func unknownKeysTolerated() throws {
        // A user downgrading, or an iCloud-synced file from a newer build.
        // Synthesized Codable ignores unknown keys — this pins that behavior.
        let futureJSON = """
            [
              {
                "id": "88888888-CDCD-4DCD-8DCD-888888888888",
                "placeID": "fixture.future",
                "name": "From The Future",
                "rating": 5.0,
                "types": ["restaurant"],
                "addedAt": "2027-01-01T00:00:00Z",
                "visitStatus": "been",
                "someFieldFromV3": {"nested": true},
                "anotherNewField": [1, 2, 3]
              }
            ]
            """
        let store = try makeSeededStore(restaurantsJSON: futureJSON)
        let restaurants = store.load()
        #expect(restaurants.count == 1)
        #expect(restaurants.first?.name == "From The Future")
    }

    // MARK: - Corruption must never cascade into data loss

    @Test("an unreadable file is quarantined, not overwritten by the next save")
    func corruptFileIsPreserved() throws {
        let garbage = "{ definitely not valid JSON ["
        let store = try makeSeededStore(restaurantsJSON: garbage)

        // Load fails soft — app still launches...
        #expect(store.load().isEmpty)

        // ...and a subsequent autosave must NOT have destroyed the only copy:
        // the original bytes survive in a quarantine file alongside the new save.
        store.save([makeRestaurant()])

        let dir = try #require(store.directoryForTesting)
        let quarantined = try FileManager.default.contentsOfDirectory(atPath: dir.path)
            .filter { $0.contains("restaurants.json.corrupt") }
        #expect(quarantined.count == 1)

        let preserved = try String(
            contentsOf: dir.appendingPathComponent(try #require(quarantined.first)),
            encoding: .utf8
        )
        #expect(preserved == garbage)
    }

    @Test("a missing file is a clean first launch, not an error")
    func missingFileLoadsEmpty() throws {
        let store = try makeSeededStore()  // no files seeded
        #expect(store.load().isEmpty)
        #expect(store.loadLists().isEmpty)

        // No quarantine file should appear — absence isn't corruption
        let dir = try #require(store.directoryForTesting)
        let contents = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        #expect(contents.allSatisfy { !$0.contains("corrupt") })
    }
}
