//
//  TestSupport.swift
//  SavorTests
//

import CoreLocation
import Foundation
import UIKit

@testable import Savor

/// Deterministic Restaurant fixture. Dates are whole seconds because ISO-8601
/// persistence truncates sub-second precision — fractional dates would break
/// round-trip equality checks.
func makeRestaurant(
    name: String = "Testaurant",
    types: [String] = ["restaurant"],
    priceLevel: Int? = nil,
    rating: Double = 4.0,
    latitude: Double? = nil,
    longitude: Double? = nil
) -> Restaurant {
    Restaurant(
        placeID: "test.\(name.lowercased())",
        name: name,
        rating: rating,
        types: types,
        addedAt: Date(timeIntervalSince1970: 1_754_000_000),
        priceLevel: priceLevel,
        editorialSummary: nil,
        latitude: latitude,
        longitude: longitude
    )
}

/// A store writing to its own unique temp directory — Swift Testing runs tests
/// in parallel, so shared paths would race.
func makeTempStore() throws -> RestaurantStore {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("savor-tests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return RestaurantStore(directory: dir)
}

struct MockPlacesError: Error {}

/// Inert PlacesProviding stub. The logic under test (lists, Smart Sort, sorting)
/// never calls the network, but AppState's init requires a service — this keeps
/// the Google SDK (and its API-key requirement) out of unit tests entirely.
@MainActor
final class MockPlacesService: PlacesProviding {
    func searchRestaurants(query: String) async -> Result<[PlaceSuggestion], Error> {
        .success([])
    }
    func createRestaurant(from suggestion: PlaceSuggestion) async -> Result<Restaurant, Error> {
        .failure(MockPlacesError())
    }
    func refreshRestaurant(_ restaurant: Restaurant) async -> Result<Restaurant, Error> {
        .success(restaurant)
    }
    func fetchCoordinate(placeID: String) async -> CLLocationCoordinate2D? {
        nil
    }
    func fetchPhotos(placeID: String, maxCount: Int) async -> [UIImage] {
        []
    }
}

/// AppState wired to an isolated temp store, pre-seeded and loaded. The store is
/// returned too so tests can simulate app relaunch (fresh AppState, same files).
@MainActor
func makeAppState(restaurants: [Restaurant] = []) throws -> (AppState, RestaurantStore) {
    let store = try makeTempStore()
    if !restaurants.isEmpty {
        store.save(restaurants)
    }
    let state = AppState(store: store, placesService: MockPlacesService())
    state.load()
    return (state, store)
}
