//
//  SearchTabView.swift
//  Savor
//

import SwiftUI

/// The search tab's content. Declared as a plain tab (not `role: .search`) in
/// RootTabView so it stays attached inline with the other tabs — the role would
/// force the system's separated-circle placement.
/// Searches *saved* spots only — finding new restaurants stays in the Add flow,
/// which bills Google per session and shouldn't be triggered by casual browsing.
struct SearchTabView: View {
    @Environment(AppState.self) private var state

    @State private var query = ""
    @State private var selectedRestaurant: Restaurant? = nil

    private var results: [Restaurant] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return state.restaurants }
        return state.restaurants.filter { restaurant in
            restaurant.name.lowercased().contains(trimmed)
                || restaurant.primaryTypeDisplay.lowercased().contains(trimmed)
                || (restaurant.editorialSummary?.lowercased().contains(trimmed) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SavorBackground()

                if state.restaurants.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing to Search", systemImage: "magnifyingglass")
                    } description: {
                        Text("Save a few spots first — search looks through your shortlist.")
                    }
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    List {
                        ForEach(results) { restaurant in
                            RestaurantRow(restaurant: restaurant) {
                                selectedRestaurant = restaurant
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Search your saved spots")
        }
        .sheet(item: $selectedRestaurant) { restaurant in
            RestaurantDetailView(restaurantID: restaurant.id)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

#if DEBUG
#Preview {
    SearchTabView()
        .environment(AppState.preview)
}
#endif
