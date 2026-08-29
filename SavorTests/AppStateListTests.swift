//
//  AppStateListTests.swift
//  SavorTests
//

import Foundation
import Testing

@testable import Savor

@MainActor
struct AppStateListTests {
    // MARK: - List CRUD

    @Test func createListTrimsWhitespaceAndRejectsEmptyNames() throws {
        let (state, _) = try makeAppState()

        let created = state.createList(name: "  Date Night  ")
        #expect(created?.name == "Date Night")
        #expect(state.createList(name: "   ") == nil)
        #expect(state.lists.count == 1)
    }

    @Test func deletingAListKeepsItsRestaurantsSaved() throws {
        let spot = makeRestaurant()
        let (state, _) = try makeAppState(restaurants: [spot])
        let list = try #require(state.createList(name: "Favorites"))
        state.addRestaurant(spot.id, toList: list.id)

        state.deleteList(id: list.id)

        #expect(state.lists.isEmpty)
        #expect(state.restaurants.count == 1)
    }

    // MARK: - Membership integrity

    @Test func addingTwiceDoesNotDuplicateMembership() throws {
        let spot = makeRestaurant()
        let (state, _) = try makeAppState(restaurants: [spot])
        let list = try #require(state.createList(name: "Favorites"))

        state.addRestaurant(spot.id, toList: list.id)
        state.addRestaurant(spot.id, toList: list.id)

        #expect(state.lists.first?.restaurantIDs == [spot.id])
    }

    /// Lists hold references — deleting a restaurant must clean up every list
    /// that points at it, or lists accumulate dangling IDs forever.
    @Test func deletingARestaurantStripsItFromEveryList() throws {
        let keep = makeRestaurant(name: "Keep")
        let gone = makeRestaurant(name: "Gone")
        let (state, _) = try makeAppState(restaurants: [keep, gone])
        let a = try #require(state.createList(name: "A"))
        let b = try #require(state.createList(name: "B"))
        state.addRestaurant(gone.id, toList: a.id)
        state.addRestaurant(gone.id, toList: b.id)
        state.addRestaurant(keep.id, toList: a.id)

        state.remove(id: gone.id)

        #expect(state.lists.allSatisfy { !$0.restaurantIDs.contains(gone.id) })
        #expect(state.lists.first { $0.id == a.id }?.restaurantIDs == [keep.id])
    }

    @Test func restaurantsInListPreservesListOrderAndDropsDanglingIDs() throws {
        let first = makeRestaurant(name: "First")
        let second = makeRestaurant(name: "Second")
        let (state, _) = try makeAppState(restaurants: [second, first])  // stored order differs
        let list = RestaurantList(
            name: "Ordered",
            restaurantIDs: [first.id, second.id, UUID()]  // trailing ID is dangling
        )

        #expect(state.restaurants(in: list).map(\.name) == ["First", "Second"])
    }

    // MARK: - Smart Sort semantics

    @Test func smartSortFilesSpotsIntoCategoryLists() throws {
        let cafe = makeRestaurant(name: "Cafe", types: ["cafe"])
        let steak = makeRestaurant(name: "Steak", types: ["steak_house"])
        let (state, _) = try makeAppState(restaurants: [cafe, steak])

        state.runSmartSort()

        let coffee = try #require(state.lists.first { $0.smartCategory == .coffee })
        let dinner = try #require(state.lists.first { $0.smartCategory == .dinner })
        #expect(coffee.restaurantIDs == [cafe.id])
        #expect(dinner.restaurantIDs == [steak.id])
    }

    @Test func smartSortRerunDoesNotDuplicate() throws {
        let cafe = makeRestaurant(name: "Cafe", types: ["cafe"])
        let (state, _) = try makeAppState(restaurants: [cafe])

        state.runSmartSort()
        state.runSmartSort()

        #expect(state.lists.count == 1)
        #expect(state.lists.first?.restaurantIDs == [cafe.id])
    }

    /// The core promise of materialized smart lists: a manual correction (moving
    /// a misfiled spot to another smart list) survives re-running Smart Sort.
    @Test func smartSortRespectsManualCorrections() throws {
        let cafe = makeRestaurant(name: "Cafe", types: ["cafe"])
        let steak = makeRestaurant(name: "Steak", types: ["steak_house"])
        let (state, _) = try makeAppState(restaurants: [cafe, steak])
        state.runSmartSort()
        let coffee = try #require(state.lists.first { $0.smartCategory == .coffee })
        let dinner = try #require(state.lists.first { $0.smartCategory == .dinner })

        // User decides the steakhouse belongs in Coffee (their call, not ours)
        state.removeRestaurant(steak.id, fromList: dinner.id)
        state.addRestaurant(steak.id, toList: coffee.id)
        state.runSmartSort()

        #expect(state.lists.first { $0.smartCategory == .dinner }?.restaurantIDs == [])
        #expect(state.lists.first { $0.smartCategory == .coffee }?.restaurantIDs == [cafe.id, steak.id])
    }

    /// Smart lists are matched by their stored category tag, not their name —
    /// renaming "Dinner" to "Fancy" must not spawn a second dinner list.
    @Test func smartSortFindsRenamedSmartLists() throws {
        let steak = makeRestaurant(name: "Steak", types: ["steak_house"])
        let (state, store) = try makeAppState(restaurants: [steak])
        state.runSmartSort()
        let dinner = try #require(state.lists.first { $0.smartCategory == .dinner })
        state.renameList(id: dinner.id, to: "Fancy")

        // A second dinner spot arrives (simulate save + reload), then re-run
        let sushi = makeRestaurant(name: "Sushi", types: ["sushi_restaurant"])
        store.save([steak, sushi])
        state.load()
        state.runSmartSort()

        let dinnerLists = state.lists.filter { $0.smartCategory == .dinner }
        #expect(dinnerLists.count == 1)
        #expect(dinnerLists.first?.name == "Fancy")
        #expect(dinnerLists.first?.restaurantIDs == [steak.id, sushi.id])
    }

    // MARK: - Persistence

    /// Every list mutation saves immediately — a "relaunch" (new AppState over
    /// the same store) must see identical state.
    @Test func listsSurviveReload() throws {
        let spot = makeRestaurant()
        let (state, store) = try makeAppState(restaurants: [spot])
        let list = try #require(state.createList(name: "Favorites"))
        state.addRestaurant(spot.id, toList: list.id)

        let relaunched = AppState(store: store, placesService: MockPlacesService())
        relaunched.load()

        // Not full equality: createList stamps a sub-second createdAt, and
        // ISO-8601 persistence truncates to whole seconds — so compare the
        // fields the store actually promises to round-trip.
        #expect(relaunched.lists.map(\.id) == state.lists.map(\.id))
        #expect(relaunched.lists.map(\.name) == state.lists.map(\.name))
        #expect(relaunched.lists.map(\.restaurantIDs) == state.lists.map(\.restaurantIDs))
        #expect(relaunched.restaurants == state.restaurants)
    }
}
