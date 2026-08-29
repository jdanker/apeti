# TODO
<!-- Actionable backlog. Prune ruthlessly; done items get deleted, not checked off
     forever. STATE.md is for awareness; this file is for work. -->

## Bugs
- [ ] `RestaurantDetailView.restaurant` force-unwraps `first(where:)` — crashes if
      the restaurant is deleted while its detail sheet is open. Return early /
      dismiss on nil instead.
- [ ] `AppState.commitAdd` trims `draftPlaceID` into a local, then saves the
      untrimmed value.

## Lists (v1.3 follow-ups)
- [ ] `ListDetailView` has no Add button — the only way to fill a list is
      long-press from Spots/Search. Consider an add flow that files straight
      into the open list.
- [ ] Swipe-delete means "remove from list" in ListDetailView but "delete
      everywhere" in Spots — consider a visual hint (label/tint) so the
      distinction is discoverable.
- [ ] Tune `SmartCategory` type tables against real saved data; lunch/dinner
      price-level fallback is a first guess.
- [ ] `RestaurantDetailView` could offer list membership (same actions as the
      row context menu).

## Chores
- [ ] Remove legacy manual-entry draft properties from `AppState` once the
      autocomplete flow is fully trusted.
- [ ] Replace blanket `.claude/` gitignore with `.claude/settings.local.json` only;
      un-ignore `CLAUDE.md`.

## Phase 1
- [ ] `SavorAPIService: PlacesProviding` targeting savor-api (blocked on server
      endpoints existing).
