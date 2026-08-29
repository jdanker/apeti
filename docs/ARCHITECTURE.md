# Savor (iOS) — Architecture

SwiftUI + Observation framework, iOS 26+, MVVM-ish with a single observable app-state
object. No Combine, no third-party state management. UIKit only where the Places SDK
requires `UIImage`.

## Structure

```mermaid
flowchart TD
    App[SavorApp<br/>entry, SDK key init] --> State[AppState<br/>@Observable @MainActor<br/>single source of truth]
    State --> Store[RestaurantStore<br/>JSON file persistence]
    State --> Proto[PlacesProviding protocol]
    Proto --> Svc[PlacesService<br/>Google Places SDK impl]
    State --> Loc[LocationService<br/>one-shot fix]
    App --> Tabs[RootTabView<br/>Spots / Lists / Search tabs] --> Views[HomeListView / ListsTabView+ListDetailView /<br/>SearchTabView / AddRestaurantView /<br/>RestaurantDetailView / PhotoCarouselView]
    Views -->|read + call mutations| State
```

Key invariants:
- **All mutations go through `AppState`** and persist immediately via `store.save` —
  no dirty/batched-save state exists.
- **`PlacesProviding` is the backend seam.** No Google SDK type crosses it; swapping
  the SDK for the Go proxy (Phase 1) is a change to one default argument in `AppState.init`.
- **Two-tier data fetching** (billing): cheap fields on save (`createRestaurant`),
  expensive fields on demand (`refreshRestaurant`, gated by 30-day `needsRefresh`).

## Code Map
<!-- Rule: every new file gets one line here, in the same change that creates it. -->

### Savor/ (app root)
- `SavorApp.swift` — entry point; reads Places key from Info.plist, initializes both Google SDKs, injects `AppState`
- `Info.plist` — Places key via `$(GOOGLE_PLACES_API_KEY)` from Secrets.xcconfig; location usage string
- `PrivacyInfo.xcprivacy` — privacy manifest (UserDefaults access reason only)

### Views/
- `RootTabView.swift` — tab shell: Spots / Lists / Search (plain tab, deliberately not `role: .search` — see decisions.md), `.tabBarMinimizeBehavior(.onScrollDown)`
- `HomeListView.swift` — Spots tab (all saved spots); defines `SortOption` + shared `apply` sort projection, swipe actions, drag-reorder (manual sort only), delete maps displayed offsets → stable IDs
- `RestaurantRow.swift` — shared row card + common interactions (tap detail, Been swipe, `ListMembershipMenu` long-press); deletion stays with parents (meaning differs per surface)
- `ListsTabView.swift` — Lists tab: overview, create/rename/delete, Smart Sort trigger; pushes detail by list *ID*
- `ListDetailView.swift` — one list's spots; per-list manual reorder, swipe-delete = remove from list only
- `SearchTabView.swift` — search tab content; local search over saved spots (name/type/summary), no API calls
- `AddRestaurantView.swift` — search sheet; 300ms debounced autocomplete through AppState's shared service, viewState enum (idle/loading/error/noResults/results)
- `RestaurantDetailView.swift` — detail sheet; lazy enrichment via `.task` + `needsRefresh`, fractional star rendering
- `PhotoCarouselView.swift` — horizontal photo scroll; skips fetch for `preview.` placeIDs

### ViewModels/
- `AppState.swift` — `@Observable @MainActor`; owns `[Restaurant]` + `[RestaurantList]`, all mutations (incl. list CRUD/membership + Smart Sort), autocomplete/photo passthroughs, distance-sort prep + coordinate backfill

### Models/
- `Restaurant.swift` — core domain model; Codable straight to JSON, type-display priority ranking, price/icon helpers, `needsRefresh`, preview data
- `RestaurantList.swift` — named list (ordered `restaurantIDs: [UUID]`, membership by reference) + `SmartCategory` enum with rule-based classifier over Google types

### Services/
- `PlacesProviding.swift` — protocol seam + `PlaceSuggestion` domain type; doc-comments the two-tier cost contract
- `PlacesService.swift` — Google SDK impl; session tokens, field masks, L1 NSCache → L2 disk → L3 API photo cache
- `LocationService.swift` — one-shot location via `CLLocationUpdate.liveUpdates`

### Storage/
- `RestaurantStore.swift` — thin JSON wrapper (`Documents/restaurants.json` + `Documents/lists.json`), ISO-8601 dates; decode failure quarantines the file (never overwritten by next save), missing file loads `[]`; directory injectable for tests

### Theme/
- `SavorTheme.swift` — color palette, `SavorBackground`, `.savorCardStyle()` card modifier

### SavorTests/ (Swift Testing, not XCTest)
- `TestSupport.swift` — fixtures (whole-second dates for ISO-8601 round-trips), temp-dir store factory, `MockPlacesService` (keeps Google SDK out of unit tests)
- `SmartCategoryTests.swift` — classifier rules: type tables, priority order, price fallback
- `SortOptionTests.swift` — shared sort projection: nil-sentinel ordering, no-location no-op
- `AppStateListTests.swift` — list CRUD, membership integrity (dedupe, strip-on-delete), Smart Sort semantics (idempotent re-run, manual corrections survive, rename-safe), persistence reload
- `PersistenceFixtures.swift` — APPEND-ONLY frozen JSON of every shipped on-disk format (v1.0/v1.1/v1.2, derived from git history); never edited to make a test pass
- `PersistenceCompatibilityTests.swift` — the data-durability gate: every shipped format decodes losslessly, round-trips intact, tolerates unknown keys; corrupt files quarantined not lost

## Integration boundary (Phase 1 target)
Today the app calls Google directly. Phase 1 replaces `PlacesService` with a
`PlacesProviding` impl that calls savor-api; the API key leaves the device.
See `savor-api/docs/ARCHITECTURE.md` for the server side.
