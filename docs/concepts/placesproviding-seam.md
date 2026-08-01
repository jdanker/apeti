# PlacesProviding — the backend seam

**What**: A `@MainActor` protocol that defines everything the app needs from "a
thing that resolves place data": autocomplete, restaurant creation, enrichment
refresh, coordinate lookup, photos. `AppState` holds `any PlacesProviding`, not
the concrete Google class.

**Why here**: This is the Phase 1 migration point. Swapping the Google SDK for the
Go proxy means writing `SavorAPIService: PlacesProviding` and changing one
default argument in `AppState.init` — zero changes to views or mutation logic.
Also the mock point for tests/previews.

**Where**: `Services/PlacesProviding.swift` (protocol + `PlaceSuggestion`),
`ViewModels/AppState.swift:init` (injection), `Services/PlacesService.swift`
(current conformance).

**Gotchas**:
- `PlaceSuggestion` text fields are currently Foundation `AttributedString` so SDK
  match-highlighting survives without leaking a Google type. **Phase 1 note:** the
  savor-api backend drops highlighting (plain strings on the wire — see
  savor-api/decisions.md), so when the migration lands these fields become plain
  `String` and this `AttributedString` choice goes away.
- Protocols can't declare default arguments — the `maxCount: 3` photo default
  lives in a protocol extension.
- The two-tier cost model (cheap on save, expensive on demand) is part of the
  protocol's *contract*, documented in its comments — any new backend must honor it.

**Deeper**: dependency inversion at module seams; see `savor-api/docs/ARCHITECTURE.md`
for the server this will point at.
