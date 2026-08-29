//
//  RestaurantRow.swift
//  Savor
//

import SwiftUI

/// The restaurant card row shared by every surface that lists spots (Spots tab,
/// list detail, search). Bundles the interactions those surfaces have in common —
/// tap for detail, long-press list-membership menu, Been swipe. Deletion is
/// deliberately *not* here: its meaning changes per surface (remove-from-list vs.
/// delete everywhere), so `onDelete` stays on each parent's ForEach.
struct RestaurantRow: View {
    @Environment(AppState.self) private var state

    let restaurant: Restaurant
    let onTap: () -> Void

    var body: some View {
        card
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .savorCardStyle()
            .onTapGesture(perform: onTap)
            .contextMenu {
                ListMembershipMenu(restaurant: restaurant)
            }
            .swipeActions(edge: .leading) {
                Button {
                    let newStatus: VisitStatus = restaurant.visitStatus == .been ? .none : .been
                    state.updateVisitStatus(for: restaurant.id, status: newStatus)
                } label: {
                    Label(
                        restaurant.visitStatus == .been ? "Unmark" : "Been",
                        systemImage: restaurant.visitStatus == .been ? "arrow.uturn.backward" : "checkmark.circle"
                    )
                }
                .tint(SavorTheme.olive)
            }
    }

    private var card: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SavorTheme.accentSoft)

                Image(systemName: restaurant.iconName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(restaurant.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(SavorTheme.ink)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    if !restaurant.priceLevelDisplay.isEmpty {
                        Text(restaurant.priceLevelDisplay)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SavorTheme.olive)
                    }
                }

                HStack(spacing: 6) {
                    Text(restaurant.primaryTypeDisplay.uppercased())
                        .font(.caption.weight(.semibold))
                        .tracking(0.6)
                        .foregroundStyle(SavorTheme.mutedInk)

                    Text("•")
                        .foregroundStyle(SavorTheme.mutedInk.opacity(0.5))

                    starRating(restaurant.rating)
                }

                if let summary = restaurant.editorialSummary, !summary.isEmpty {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(SavorTheme.mutedInk)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if restaurant.visitStatus != .none {
                        statusBadge(for: restaurant.visitStatus)
                    }

                    Text("Added \(restaurant.addedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(SavorTheme.mutedInk.opacity(0.8))
                }
            }
        }
    }

    private func starRating(_ rating: Double) -> some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: rating >= Double(i) - 0.25 ? "star.fill"
                     : rating >= Double(i) - 0.75 ? "star.leadinghalf.filled"
                     : "star")
            }
        }
        .font(.caption2)
        .foregroundStyle(SavorTheme.gold)
    }

    @ViewBuilder
    private func statusBadge(for status: VisitStatus) -> some View {
        let (icon, color) = statusIconAndColor(for: status)

        Label(status.label, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.16), in: Capsule())
    }

    private func statusIconAndColor(for status: VisitStatus) -> (String, Color) {
        switch status {
        case .been:
            return ("checkmark.circle.fill", SavorTheme.olive)
        case .none:
            return ("", .clear)
        }
    }
}

/// Context-menu content for toggling which lists a restaurant belongs to.
/// Also the correction path for Smart Sort misfiles (move a spot out of Dinner,
/// into Lunch) — checkmark marks current lists, tapping toggles.
struct ListMembershipMenu: View {
    @Environment(AppState.self) private var state

    let restaurant: Restaurant

    var body: some View {
        if state.lists.isEmpty {
            // Text renders as a disabled menu item — informative, not tappable
            Text("No lists yet — create one in the Lists tab")
        } else {
            ForEach(state.lists) { list in
                let isMember = list.restaurantIDs.contains(restaurant.id)
                Button {
                    if isMember {
                        state.removeRestaurant(restaurant.id, fromList: list.id)
                    } else {
                        state.addRestaurant(restaurant.id, toList: list.id)
                    }
                } label: {
                    Label(list.name, systemImage: isMember ? "checkmark" : list.iconName)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    List {
        RestaurantRow(restaurant: Restaurant.previewData[0]) {}
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
    .listStyle(.plain)
    .environment(AppState.preview)
}
#endif
