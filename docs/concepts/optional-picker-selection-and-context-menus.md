# Optional Picker selection & row context menus

**What**: Two SwiftUI techniques introduced with multi-list support. (1) A `Picker`
bound to an *optional* selection (`UUID?`) so "no list selected" is a real,
pickable state — the trap is that every `.tag()` must match the selection type
*exactly*, so the nil case needs an explicit cast (`.tag(nil as UUID?)`) and list
rows need `.tag(Optional(list.id))`; a bare `.tag(list.id)` is a `UUID`, not a
`UUID?`, and selection silently never updates. (2) `.contextMenu` attaches a
long-press menu to any view — SwiftUI rebuilds its content on each open, so
membership checkmarks computed inline from current state are always fresh, no
invalidation bookkeeping.

**Why here**: The list switcher needed "All Spots" as a first-class state, not a
sentinel list stored on disk — optional selection models that directly, and the
scope degrades gracefully to All Spots if the selected list is deleted (the
computed `selectedList` just resolves to nil). The context menu is the correction
path for Smart Sort misfiles: membership is toggled per-row without navigating
anywhere, which matters because materialized smart lists (see decisions.md) rely
on cheap manual correction.

**Where**: `Savor/Views/HomeListView.swift:108` (optional-tag Picker),
`Savor/Views/HomeListView.swift:308` (membership context menu),
`Savor/Views/HomeListView.swift:171` (selectedList nil-degradation).

**Gotchas**:
- Tag/selection type mismatch fails silently — no compiler error, the Picker just
  never updates. First place to look if list switching "does nothing".
- `.contextMenu` and `.onTapGesture` on the same row coexist, but the long-press
  also highlights the row; don't add `.onLongPressGesture` separately or they race.

**Deeper**: https://developer.apple.com/documentation/swiftui/picker (see "Iterating over a picker's options")
