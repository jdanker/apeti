# Swift Testing (the framework)

**What**: Apple's replacement for XCTest (Xcode 16+): `import Testing`, `@Test`
functions, `#expect(...)` for soft assertions and `try #require(...)` for hard
ones (unwraps optionals or fails-and-stops). No `XCTestCase` subclass, no `setUp`
— each test gets a *fresh instance* of its suite struct, so instance state can't
leak between tests. The macro-based `#expect` captures the whole expression and
prints sub-values on failure (`#expect(a == b)` shows both sides), which is why
there's no `XCTAssertEqual`-style zoo of assertion variants. Key difference that
bites: tests run **in parallel by default** (XCTest was serial), so anything
touching shared resources — files, singletons — must be isolated per test.

**Why here**: Savor's baseline tests cover the pure logic layer (Smart Sort
classifier, sort projection, AppState list mutations). Parallelism drove two
design choices in `TestSupport.swift`: every test gets its own temp-dir
`RestaurantStore` (a shared path would race), and `RestaurantStore` gained an
injectable `directory:` parameter — without it, unit tests would read/write the
*real* app container's JSON in the simulator. `MockPlacesService` satisfies
`PlacesProviding` inertly, proving the seam works: AppState logic tests never
initialize the Google SDK or need an API key. `@MainActor` on the AppState suite
matches AppState's own isolation.

**Where**: `SavorTests/TestSupport.swift` (fixtures, temp store, mock),
`SavorTests/AppStateListTests.swift:11` (`@MainActor` suite),
`Savor/Storage/RestaurantStore.swift:16` (injectable directory).

**Gotchas**:
- ISO-8601 persistence truncates dates to whole seconds — full-equality
  assertions across a save/load boundary fail unless fixtures use whole-second
  dates or the comparison skips timestamps (see `listsSurviveReload`).
- The shared Xcode scheme needed an explicit `<Testables>` block before
  `xcodebuild test` would run at all ("Scheme is not currently configured for
  the test action") — auto-created test plans don't always materialize for
  CLI-only workflows.

**Deeper**: https://developer.apple.com/documentation/testing
