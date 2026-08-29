import CoreLocation
import SwiftUI

/// How the saved list is ordered. Sorting is a view-level projection — the persisted
/// array order always means "manual order", so no sort ever calls store.save.
enum SortOption: String, CaseIterable, Identifiable {
    case manual = "Manual"
    case price = "Price"
    case rating = "Rating"
    case distance = "Distance"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .manual: return "hand.draw"
        case .price: return "dollarsign.circle"
        case .rating: return "star"
        case .distance: return "location"
        }
    }

    /// The shared sort projection, used by every surface that displays spots
    /// (Spots tab, list detail). Pure — never mutates or persists; manual returns
    /// the input order untouched.
    func apply(to restaurants: [Restaurant], userLocation: CLLocation?) -> [Restaurant] {
        switch self {
        case .manual:
            return restaurants
        case .price:
            // Cheapest first; nil (no price data from Google) maps to Int.max so
            // unpriced restaurants sort last — same sentinel approach as distance.
            return restaurants.sorted { ($0.priceLevel ?? Int.max) < ($1.priceLevel ?? Int.max) }
        case .rating:
            // Best first; unrated restaurants carry 0.0 so they naturally land last
            return restaurants.sorted { $0.rating > $1.rating }
        case .distance:
            // Until the location fix arrives (or if denied), show the manual order
            guard let here = userLocation else { return restaurants }
            return restaurants.sorted {
                ($0.distance(from: here) ?? .greatestFiniteMagnitude)
                    < ($1.distance(from: here) ?? .greatestFiniteMagnitude)
            }
        }
    }
}

struct HomeListView: View {
    @Environment(AppState.self) private var state

    @State private var selectedRestaurant: Restaurant? = nil
    @State private var sortOption: SortOption = .manual

    var body: some View {
        @Bindable var state = state

        NavigationStack {
            ZStack {
                SavorBackground()

                if state.restaurants.isEmpty {
                    emptyState
                } else {
                    List {
                        if sortOption == .distance && state.locationDenied {
                            locationDeniedNotice
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }

                        Section("Saved Spots") {
                            ForEach(sortedRestaurants) { restaurant in
                                RestaurantRow(restaurant: restaurant) {
                                    selectedRestaurant = restaurant
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                // Reordering a sorted projection is meaningless (it would
                                // snap back), so drag-to-reorder only exists in manual order.
                                // moveDisabled (vs. a conditional onMove handler) also avoids
                                // an @MainActor function-conversion error under Swift 6.2's
                                // default-isolation settings.
                                .moveDisabled(sortOption != .manual)
                            }
                            .onDelete(perform: delete)
                            .onMove(perform: state.move)
                        }
                        .textCase(nil)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Savor")
                            .font(.title.weight(.bold))
                            .fontDesign(.serif)
                            .foregroundStyle(SavorTheme.ink)
                        Text("Your restaurant shortlist")
                            .font(.caption)
                            .foregroundStyle(SavorTheme.mutedInk)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Restaurant", systemImage: "plus") {
                        state.isPresentingAdd = true
                    }
                    .font(.headline)
                    .foregroundStyle(SavorTheme.accent)
                }
            }
            .onChange(of: sortOption) { _, newValue in
                // Location fix + coordinate backfill are only needed (and only billed/
                // prompted) once the user actually asks for distance ordering
                if newValue == .distance {
                    Task { await state.prepareDistanceSort() }
                }
            }
        }
        .sheet(isPresented: $state.isPresentingAdd) {
            AddRestaurantView()
        }
        .sheet(item: $selectedRestaurant) { restaurant in
            RestaurantDetailView(restaurantID: restaurant.id)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var sortedRestaurants: [Restaurant] {
        sortOption.apply(to: state.restaurants, userLocation: state.userLocation)
    }

    /// Swipe-to-delete hands us offsets into the *displayed* (sorted) array, which may
    /// not match the stored array's order — map to stable IDs before mutating.
    /// Here in All Spots, delete means "delete everywhere" (and strips the spot from
    /// every list); inside a list (ListDetailView) it only removes from that list.
    private func delete(atOffsets offsets: IndexSet) {
        let ids = offsets.map { sortedRestaurants[$0].id }
        for id in ids {
            state.remove(id: id)
        }
    }

    private var locationDeniedNotice: some View {
        Label("Enable location access in Settings to sort by distance.", systemImage: "location.slash")
            .font(.caption)
            .foregroundStyle(SavorTheme.mutedInk)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(SavorTheme.accent)
                    .frame(width: 88, height: 88)

                Image(systemName: "fork.knife")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.white)
            }

            Text("Build your first shortlist")
                .font(.system(.title2, design: .serif, weight: .bold))
                .foregroundStyle(SavorTheme.ink)

            Text("Save restaurants that look promising, then mark the ones that were actually worth the reservation.")
                .font(.subheadline)
                .foregroundStyle(SavorTheme.mutedInk)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Button {
                state.isPresentingAdd = true
            } label: {
                Label("Add a Restaurant", systemImage: "plus")
                    .font(.headline.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(SavorTheme.accent, in: Capsule())
                    .foregroundStyle(Color.white)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview {
    HomeListView()
        .environment(AppState.preview)
}
#endif
