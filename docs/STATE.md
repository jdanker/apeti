# STATE
<!-- Overwritten at the end of every working session. Keep under ~20 lines. -->
_Last updated: 2026-07-20_

## Works now (v1.2 in repo)
- List: sort (manual/price/rating/distance), reorder, swipe delete + Been toggle
- Add: debounced autocomplete → place details → save (cheap fields only)
- Detail: photo carousel, lazy enrichment (website + review summary, 30-day refresh)
- Distance sort: one-shot location fix + lazy coordinate backfill for old saves
- Persistence: `Documents/restaurants.json`, save-on-every-mutation

## In flight
- Nothing mid-implementation.

## Next
1. Phase 1: `SavorAPIService: PlacesProviding` targeting savor-api endpoints
2. Map savor-api JSON → `PlaceSuggestion` / `Restaurant`. Wire format decided
   server-side: priceLevel nullable int, plain-string suggestion text (no highlighting),
   photos as URIs. `PlaceSuggestion` can drop `AttributedString` → plain `String`.

## Landmines
- No Discover/MapKit tab exists — old roadmap docs mentioning it are aspirational
- Sort is a view projection; delete/reorder logic depends on stable IDs (see decisions.md)
- Known bugs tracked in docs/TODO.md — check before touching AppState or DetailView
- Phase 1 wire contract now lives in savor-api/docs (decisions.md + ARCHITECTURE Phase 1
  API surface) — read it before writing `SavorAPIService`
