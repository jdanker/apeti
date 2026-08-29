# Search-role tabs & the iOS 26 tab bar

**What**: Since iOS 18, `TabView` tabs are declared with the `Tab` builder type,
and a tab can carry a semantic *role*. `Tab(role: .search)` tells the system
"this is the search destination" — the system then owns its icon, position, and
presentation entirely. On iOS 26's Liquid Glass tab bar that means a *separated*
trailing circle that morphs into the search field when tapped. There is no
placement control: `TabRole` exposes only `.search` with no options, and the
related `tabViewSearchActivation(_:)` modifier only controls *when* search
activates (`.automatic` vs `.searchTabSelection`), not where the tab renders —
verified against the iOS 26.5 SDK swiftinterface. Separately,
`.tabBarMinimizeBehavior(.onScrollDown)` (iOS 26) makes the bar shrink away on
scroll-down and return on scroll-up — system-provided, no scroll-offset tracking.

**Why here**: Savor tried the role first, then dropped it (see decisions.md):
recent iOS builds moved Apple's own apps to an *attached* search tab, and with
the role there is no way to opt out of the separated placement. Search is now a
plain `Tab("Search", systemImage: "magnifyingglass")` + `.searchable` inside the
tab's NavigationStack. The general lesson: a semantic role is a trade — you get
system behavior for free, but you inherit *all* of it, including the parts that
later drift from the look you want. The search tab also enforces a billing
boundary: it filters local data only; anything hitting the Google Places API
stays behind the explicit Add flow.

**Where**: `Savor/Views/RootTabView.swift:20` (plain tab + rationale comment),
`Savor/Views/SearchTabView.swift:59` (`.searchable` binding),
`Savor/Views/RootTabView.swift:28` (minimize behavior).

**Gotchas**:
- Checking what an SDK actually exposes beats guessing: the framework's
  `.swiftinterface` under the active SDK path is greppable
  (`xcrun --show-sdk-path` → `SwiftUI.framework/Modules/SwiftUI.swiftmodule/`).
- If Apple later ships an attached mode for role-search tabs, switching back
  restores the semantics (fixed icon, one-per-TabView, activation morph).

**Deeper**: https://developer.apple.com/documentation/swiftui/tabrole
