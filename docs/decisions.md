# Decisions
<!-- Append-only. One dated paragraph per non-obvious tradeoff. Newest at top. -->

**2026-07 — Sort is a view-level projection, never persisted.** The stored array
order always means "manual order"; price/rating/distance sorts are computed in
`HomeListView.sortedRestaurants` and never call `store.save`. Consequences: reorder
is disabled outside manual sort (it would snap back), and delete must map displayed
offsets to stable IDs before mutating.

**2026-07 — Coordinates stored as optional `Double`s, backfilled lazily.** Keeps
`Restaurant` Codable without conditional conformances, lets pre-1.2 saves decode
cleanly, and defers the (cheapest-SKU) coordinate fetch until the user actually
picks distance sort — no billing or permission prompt for a feature never used.

**2026-07 — `PlacesProviding` protocol as the backend seam.** Views and AppState
never see Google SDK types; `PlaceSuggestion` uses Foundation `AttributedString`
so SDK match-highlighting survives without leaking a Google type. Phase 1 (Go proxy)
becomes a new conforming type + one default-argument change.

**2026-07 — Two-tier field fetching for Places billing.** On save: cheap fields
only (name, rating, price, types, editorial summary, photos, website). On demand
(detail view, 30-day staleness gate): expensive fields like `reviewSummary`.
Autocomplete session tokens are reset after each detail fetch — session-based
pricing, not incidental.

**2026-08 — Lists reference restaurants by ID, never by copy.** `RestaurantList`
holds an ordered `restaurantIDs: [UUID]`; `AppState.restaurants` stays the single
source of truth. Membership is many-to-many (one spot in Coffee *and* Breakfast),
enrichment updates apply everywhere at once, and per-list manual drag-order lives
in each list's own ID array. Consequence: every restaurant deletion must strip the
ID from all lists (`stripFromAllLists`). Lists persist to a separate `lists.json`
so pre-existing `restaurants.json` saves decode with zero migration. "All Spots"
is a projection of the full array, not a stored list.

**2026-08 — Smart Sort materializes real lists and never re-files a spot.** The
classifier (`SmartCategory.classify`) is pure rules over the Google types already
stored on each restaurant — no API calls, no billing. It materializes editable
lists (rather than computing dynamic groups) so misclassifications can be
corrected by hand; re-runs skip any restaurant already in *any* smart list, so a
manual move from Dinner to Lunch survives. Smart lists are found by their stored
`smartCategory` tag, so renaming one doesn't orphan it. Lunch-vs-dinner has no
Google type signal, so unmatched restaurants fall back on price level ($ → lunch,
else dinner) — a heuristic, expected to be tuned.

**2026-08 — Lists promoted to a tab; search gets the system search-role tab.**
The in-view folder scope switcher was replaced by a Lists tab that pushes
`ListDetailView` by list *ID* (resolved live from AppState, so a list deleted
while visible degrades gracefully — no dangling-selection state to manage).
Dynamic per-list tabs were rejected: tab bars need a stable, bounded destination
set. Search uses `Tab(role: .search)` rather than a regular tab — the role is
what buys the iOS 26 system treatment (separated trailing position, morph into
the search field) — and searches saved spots only; Google-billed discovery stays
behind the explicit Add flow. Row card + shared interactions extracted to
`RestaurantRow`/`ListMembershipMenu` so all three surfaces render one way;
deletion deliberately stays with each parent because its meaning differs
(remove-from-list vs. delete-everywhere).

**2026-08 — Search is a plain tab, not `Tab(role: .search)`.** Reversal of the
same-day decision above. The role hands placement to the system, which renders
the search tab as a *separated* trailing circle with no API to keep it attached
(`TabRole` has no options; `tabViewSearchActivation` only controls activation
timing — verified against the iOS 26.5 SDK swiftinterface). Recent iOS builds
moved Apple's own apps to an attached search tab, so a plain
`Tab("Search", systemImage:)` now matches the platform look; the only cost is
the circle-morph animation, which was the thing being removed. If Apple ships
an attached mode for role-search tabs, revert to the role for the semantics.
