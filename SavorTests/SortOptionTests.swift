//
//  SortOptionTests.swift
//  SavorTests
//

import CoreLocation
import Testing

@testable import Savor

struct SortOptionTests {
    @Test func manualReturnsInputOrderUntouched() {
        let input = [makeRestaurant(name: "B"), makeRestaurant(name: "A")]
        #expect(SortOption.manual.apply(to: input, userLocation: nil) == input)
    }

    @Test func priceSortsCheapestFirstWithUnpricedLast() {
        let cheap = makeRestaurant(name: "Cheap", priceLevel: 1)
        let pricey = makeRestaurant(name: "Pricey", priceLevel: 4)
        let unpriced = makeRestaurant(name: "Unpriced", priceLevel: nil)

        let sorted = SortOption.price.apply(to: [unpriced, pricey, cheap], userLocation: nil)
        #expect(sorted.map(\.name) == ["Cheap", "Pricey", "Unpriced"])
    }

    @Test func ratingSortsBestFirst() {
        let low = makeRestaurant(name: "Low", rating: 3.1)
        let high = makeRestaurant(name: "High", rating: 4.8)
        let unrated = makeRestaurant(name: "Unrated", rating: 0.0)

        let sorted = SortOption.rating.apply(to: [low, unrated, high], userLocation: nil)
        #expect(sorted.map(\.name) == ["High", "Low", "Unrated"])
    }

    /// Before the location fix arrives (or when denied), distance sort must not
    /// reshuffle — the view shows manual order rather than something arbitrary.
    @Test func distanceWithoutLocationKeepsInputOrder() {
        let input = [makeRestaurant(name: "B"), makeRestaurant(name: "A")]
        #expect(SortOption.distance.apply(to: input, userLocation: nil) == input)
    }

    @Test func distanceSortsNearestFirstWithMissingCoordinatesLast() {
        // User at origin; "Near" ~1km away, "Far" ~100km, "NoCoords" pre-1.2 save
        let here = CLLocation(latitude: 47.6062, longitude: -122.3321)
        let near = makeRestaurant(name: "Near", latitude: 47.6152, longitude: -122.3321)
        let far = makeRestaurant(name: "Far", latitude: 48.5, longitude: -122.3321)
        let noCoords = makeRestaurant(name: "NoCoords")

        let sorted = SortOption.distance.apply(to: [noCoords, far, near], userLocation: here)
        #expect(sorted.map(\.name) == ["Near", "Far", "NoCoords"])
    }
}
