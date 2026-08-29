//
//  RestaurantList.swift
//  Savor
//

import Foundation

/// A named, ordered collection of saved restaurants. Membership is by ID —
/// `AppState.restaurants` stays the single source of truth, so a spot can live in
/// several lists without duplicating its data, and enrichment/refresh updates apply
/// everywhere at once. Deleting a restaurant just strips its ID from every list.
struct RestaurantList: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var iconName: String
    // An ordered array (not a Set) so each list keeps its own manual drag-order,
    // independent of the main array's order.
    var restaurantIDs: [UUID]
    // Set when Smart Sort created this list — lets a re-run find "its" list even
    // after the user renames it. nil means user-created; Smart Sort never touches it.
    var smartCategory: SmartCategory?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "list.bullet",
        restaurantIDs: [UUID] = [],
        smartCategory: SmartCategory? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.restaurantIDs = restaurantIDs
        self.smartCategory = smartCategory
        self.createdAt = createdAt
    }
}

/// The categories Smart Sort files restaurants into. Classification is rule-based
/// over the Google place types already stored on each Restaurant — no API calls,
/// no billing impact.
enum SmartCategory: String, Codable, CaseIterable {
    case coffee
    case breakfast
    case lunch
    case dinner
    case takeout

    var displayName: String {
        switch self {
        case .coffee: return "Coffee Shops"
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .takeout: return "Takeout"
        }
    }

    var iconName: String {
        switch self {
        case .coffee: return "cup.and.saucer.fill"
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .takeout: return "bag.fill"
        }
    }

    // Raw Google place-type strings (same snake_case values Restaurant.types holds).
    private static let coffeeTypes: Set<String> = [
        "coffee_shop", "cafe", "tea_house", "cat_cafe", "dog_cafe", "internet_cafe",
    ]
    private static let breakfastTypes: Set<String> = [
        "breakfast_restaurant", "brunch_restaurant", "diner", "bakery",
        "bagel_shop", "donut_shop",
    ]
    private static let takeoutTypes: Set<String> = [
        "meal_takeaway", "meal_delivery", "fast_food_restaurant",
    ]
    private static let lunchTypes: Set<String> = [
        "sandwich_shop", "deli", "cafeteria", "food_court",
    ]
    private static let dinnerTypes: Set<String> = [
        "steak_house", "fine_dining_restaurant", "wine_bar", "bar_and_grill",
        "sushi_restaurant",
    ]

    /// Rule-based classification, checked in specificity order: many cafes also
    /// carry the generic "restaurant" type, so coffee must win before any fallback.
    /// Google has no mealtime type, so lunch-vs-dinner for unmatched restaurants
    /// falls back on price level — cheap ($ or unpriced-cheap) reads as lunch,
    /// everything else defaults to dinner.
    static func classify(_ restaurant: Restaurant) -> SmartCategory {
        let types = Set(restaurant.types)
        if !types.isDisjoint(with: coffeeTypes) { return .coffee }
        if !types.isDisjoint(with: breakfastTypes) { return .breakfast }
        if !types.isDisjoint(with: takeoutTypes) { return .takeout }
        if !types.isDisjoint(with: lunchTypes) { return .lunch }
        if !types.isDisjoint(with: dinnerTypes) { return .dinner }
        return (restaurant.priceLevel ?? 2) <= 1 ? .lunch : .dinner
    }
}
