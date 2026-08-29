# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Collaboration ground rules

The user is an experienced platform/DevOps engineer, newer to iOS/SwiftUI, using
Claude as a learning-focused pair programmer. Rules:
- Don't make sweeping changes silently; explain trade-offs before implementing.
- Flag anti-patterns instead of quietly fixing them (unfixed ones → `docs/TODO.md`).
- Explain the *why* behind unfamiliar iOS/Swift tech — and record it in
  `docs/concepts/` so it survives the session.

## Data durability invariant (never break this)

An app update must NEVER lose a user's saved restaurants or lists. Persisted
formats are forever — every JSON shape a shipped version ever wrote must decode
in every future version. Concretely:

- New fields on `Restaurant`/`RestaurantList` must be optional or defaulted.
- Never remove or rename a `Codable` key or a persisted enum case
  (`VisitStatus`, `SmartCategory`); adding cases is fine.
- Storage filenames (`restaurants.json`, `lists.json`) and the ISO-8601 date
  strategy never change without an explicit migration.
- `SavorTests/PersistenceCompatibilityTests.swift` enforces this against frozen
  per-version fixtures in `PersistenceFixtures.swift`. Fixtures are APPEND-ONLY:
  if a compat test fails, fix the model — never edit a fixture to make it pass.
  When a release changes the persisted format, freeze a new fixture for it.

**Structure, invariants, and current state live in `docs/` — read before non-trivial work:**
- `docs/ARCHITECTURE.md` — app structure, invariants, Code Map (every file, one line)
- `docs/STATE.md` — where the project stands right now
- `docs/TODO.md` — actionable backlog (known bugs live here); pull next steps from here
- `docs/decisions.md` — why non-obvious choices were made
- `docs/concepts/` — the learning record: one file per iOS/Swift concept used here

Start returning sessions with `/resume`.

## Commands

Build and test via `xcodebuild` (scheme: `Savor`, project: `Savor.xcodeproj`):

```bash
# Build for the simulator
xcodebuild -project Savor.xcodeproj -scheme Savor -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run all tests (unit + UI)
xcodebuild -project Savor.xcodeproj -scheme Savor -destination 'platform=iOS Simulator,name=iPhone 17' test

# Run a single test (Swift Testing framework, not XCTest)
xcodebuild -project Savor.xcodeproj -scheme Savor -destination 'platform=iOS Simulator,name=iPhone 17' \
  test -only-testing:SavorTests/SavorTests/example
```

In practice, day-to-day iteration happens in Xcode itself (Cmd+R / Cmd+U) — reach
for `xcodebuild` mainly for scripted/CI-style verification.

Tests use **Swift Testing** (`import Testing`, `@Test`, `#expect`), not XCTest —
`SavorTests/` currently has only a placeholder; `SavorUITests/` has launch tests.

## Secrets

`Savor/Secrets.xcconfig` holds `GOOGLE_PLACES_API_KEY` and is gitignored. Referenced
from `Info.plist` as `GooglePlacesAPIKey`, read in `SavorApp.swift` at launch to
initialize both `GMSPlacesClient` (legacy) and `PlacesClient` (GooglePlacesSwift).
The app `fatalError`s at launch if the key is missing — the file must exist locally
before building.

## Integration boundary (important, easy to get wrong)

The app currently calls the Google Places SDK **directly** — no backend in the loop
yet, despite `savor-api` existing and being deployed. Don't assume requests are
proxied through Go unless you've checked `docs/STATE.md`. The migration seam is the
`PlacesProviding` protocol — see `docs/concepts/placesproviding-seam.md`.

## Living docs maintenance

`docs/` is the project's memory and the user's learning record — written for a
platform engineer learning iOS, concise, no fluff. Rules:

- `STATE.md` — **overwrite** (never append) at session end: works now / in flight /
  next / landmines. Under ~20 lines.
- `ARCHITECTURE.md` Code Map — every new file gets a one-line entry **in the same
  change that creates it**. Structural changes update the diagram/invariants.
- `concepts/` — create from `_template.md` **whenever a feature involves iOS/Swift
  tech the user hasn't seen in this project yet** (framework, macro, SDK pattern,
  SwiftUI technique). Always include `file:line` pointers. This is the audit trail
  of what was implemented and why.
- `decisions.md` — append-only, one dated paragraph per non-obvious tradeoff.
  Trade-offs explained per the ground rules should land here, not evaporate in chat.
- `TODO.md` — actionable backlog. Bugs/chores/anti-patterns found but not fixed
  in-session go here. Delete done items; prune ruthlessly.

**Update triggers**: new dependency/framework/API; first use of a pattern; module
boundary or data-flow change; non-obvious tradeoff decided. **Not**: bugfixes,
styling, refactors within existing patterns. Test: "would the user need this
re-explained in 3 weeks?"

**Cadence**: never interleave doc edits mid-implementation. At session end, propose
all doc updates as one reviewable batch (that review is a deliberate learning
checkpoint), then rewrite STATE.md.
