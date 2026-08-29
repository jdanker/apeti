# STATE
<!-- Overwritten at the end of every working session. Keep under ~20 lines. -->
_Last updated: 2026-08-08_

## Works now (v1.3 in repo)
- Tabs: Spots / Lists / Search (plain attached tab — role .search rejected,
  see decisions.md; bar minimizes on scroll-down)
- Spots: sort (manual/price/rating/distance), reorder, swipe delete + Been toggle
- Lists: create/rename/delete in Lists tab, push into list detail (per-list manual
  order, swipe = remove-from-list), long-press any row → toggle membership
- Smart Sort (Lists tab toolbar): rule-based classifier over stored Google types,
  materializes editable lists, re-runs skip already-filed spots
- Search tab: local filter over saved spots (name/type/summary), no API calls
- Add: debounced autocomplete → place details → save (cheap fields only)
- Detail: photo carousel, lazy enrichment (website + review summary, 30-day refresh)
- Persistence: `restaurants.json` + `lists.json`, save-on-every-mutation
- Tests: 19 baseline unit tests (classifier, sort projection, list mutations,
  persistence reload) — Swift Testing, isolated temp-dir stores, mocked Places

## In flight
- Nothing mid-implementation.

## Next
1. Lists follow-ups in TODO.md (add-into-list flow, delete-semantics hint)
2. Phase 1: `SavorAPIService: PlacesProviding` targeting savor-api endpoints

## Landmines
- Tests run in parallel — anything touching files needs its own temp dir
  (see TestSupport.makeTempStore); scheme's Testables block was added by hand
- Swipe-delete: remove-from-list in ListDetailView, delete-everywhere in Spots
  (also strips the ID from all lists via `stripFromAllLists`)
- Shared row UI lives in `RestaurantRow`; deletion handlers stay per-surface
- Sort projection is shared as `SortOption.apply` — defined in HomeListView.swift
- Known bugs tracked in docs/TODO.md — check before touching AppState or DetailView
