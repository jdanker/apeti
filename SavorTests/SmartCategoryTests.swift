//
//  SmartCategoryTests.swift
//  SavorTests
//

import Testing

@testable import Savor

struct SmartCategoryTests {
    @Test func explicitTypesMapToTheirCategories() {
        #expect(SmartCategory.classify(makeRestaurant(types: ["coffee_shop"])) == .coffee)
        #expect(SmartCategory.classify(makeRestaurant(types: ["breakfast_restaurant"])) == .breakfast)
        #expect(SmartCategory.classify(makeRestaurant(types: ["meal_takeaway"])) == .takeout)
        #expect(SmartCategory.classify(makeRestaurant(types: ["sandwich_shop"])) == .lunch)
        #expect(SmartCategory.classify(makeRestaurant(types: ["steak_house"])) == .dinner)
    }

    /// Real Google results carry generic types alongside specific ones — the
    /// specific type must win regardless of array order.
    @Test func cafeBeatsGenericRestaurantType() {
        let cafe = makeRestaurant(types: ["restaurant", "point_of_interest", "cafe"])
        #expect(SmartCategory.classify(cafe) == .coffee)
    }

    /// Categories are checked in a fixed priority order (coffee first) so a place
    /// carrying types from two tables classifies deterministically.
    @Test func coffeeOutranksBreakfastWhenBothMatch() {
        let bakeryCafe = makeRestaurant(types: ["bakery", "cafe"])
        #expect(SmartCategory.classify(bakeryCafe) == .coffee)
    }

    /// No mealtime type from Google → price level is the tiebreaker:
    /// cheap reads as lunch, everything else (including unknown) as dinner.
    @Test func unmatchedTypesFallBackOnPriceLevel() {
        #expect(SmartCategory.classify(makeRestaurant(types: ["restaurant"], priceLevel: 1)) == .lunch)
        #expect(SmartCategory.classify(makeRestaurant(types: ["restaurant"], priceLevel: 3)) == .dinner)
        #expect(SmartCategory.classify(makeRestaurant(types: ["restaurant"], priceLevel: nil)) == .dinner)
    }
}
