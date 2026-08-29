//
//  ListDetailView.swift
//  Savor
//

import SwiftUI

/// One list's spots, pushed from the Lists tab. Holds only the list ID and
/// resolves the list from AppState each render — if the list is deleted while
/// visible, the view degrades to its empty state instead of crashing on a
/// stale copy.
struct ListDetailView: View {
    @Environment(AppState.self) private var state

    let listID: UUID

    @State private var selectedRestaurant: Restaurant? = nil
    @State private var sortOption: SortOption = .manual

    private var list: RestaurantList? {
        state.lists.first { $0.id == listID }
    }

    /// Members in the list's own manual order, then the shared sort projection.
    private var sortedRestaurants: [Restaurant] {
        guard let list else { return [] }
        return sortOption.apply(to: state.restaurants(in: list), userLocation: state.userLocation)
    }

    var body: some View {
        ZStack {
            SavorBackground()

            if sortedRestaurants.isEmpty {
                emptyState
            } else {
                List {
                    if sortOption == .distance && state.locationDenied {
                        locationDeniedNotice
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }

                    ForEach(sortedRestaurants) { restaurant in
                        RestaurantRow(restaurant: restaurant) {
                            selectedRestaurant = restaurant
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .moveDisabled(sortOption != .manual)
                    }
                    .onDelete(perform: removeFromList)
                    .onMove { source, destination in
                        state.move(inList: listID, fromOffsets: source, toOffset: destination)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(list?.name ?? "")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort by", selection: $sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Label(option.rawValue, systemImage: option.icon)
                                .tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.headline)
                        .foregroundStyle(SavorTheme.accent)
                }
            }
        }
        .onChange(of: sortOption) { _, newValue in
            if newValue == .distance {
                Task { await state.prepareDistanceSort() }
            }
        }
        .sheet(item: $selectedRestaurant) { restaurant in
            RestaurantDetailView(restaurantID: restaurant.id)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    /// Inside a list, swipe-delete means "remove from this list" — the restaurant
    /// stays saved (All Spots and other lists are untouched).
    private func removeFromList(atOffsets offsets: IndexSet) {
        let ids = offsets.map { sortedRestaurants[$0].id }
        for id in ids {
            state.removeRestaurant(id, fromList: listID)
        }
    }

    private var locationDeniedNotice: some View {
        Label("Enable location access in Settings to sort by distance.", systemImage: "location.slash")
            .font(.caption)
            .foregroundStyle(SavorTheme.mutedInk)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Nothing Here Yet", systemImage: "tray")
        } description: {
            Text("Long-press a spot in the Spots tab to add it to this list.")
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ListDetailView(listID: UUID())
    }
    .environment(AppState.preview)
}
#endif
