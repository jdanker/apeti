//
//  PersistenceFixtures.swift
//  SavorTests
//
//  Frozen samples of what each SHIPPED app version wrote to disk.
//
//  ⚠️ APPEND-ONLY. These strings are historical artifacts, not living code.
//  If a compatibility test fails, the bug is in the model/store — fix it there.
//  Never edit an existing fixture to make a test pass: that silently revokes
//  the guarantee that an app update can read every user's existing saves.
//  When a release changes the persisted format, freeze a NEW fixture here.
//
//  Shapes were derived from git history, not memory:
//    v1.0 → commit dd38816 (Restaurant without enrichment fields)
//    v1.1 → commit 4e88a7b (+ websiteURL, reviewSummary, lastRefreshedAt)
//    v1.2 → current       (+ latitude/longitude; lists.json introduced)
//
//  Keys are omitted (not null) where a field was absent — matching JSONEncoder's
//  encodeIfPresent behavior for nil optionals, which is what real files contain.
//

enum PersistenceFixtures {
    /// restaurants.json as written by v1.0.
    static let restaurantsV1_0 = """
        [
          {
            "id": "11111111-AAAA-4AAA-8AAA-111111111111",
            "placeID": "fixture.pappys",
            "name": "Pappy's Smokehouse",
            "rating": 4.7,
            "types": ["barbecue_restaurant", "restaurant"],
            "priceLevel": 2,
            "editorialSummary": "St. Louis BBQ institution.",
            "addedAt": "2025-10-01T18:30:00Z",
            "visitStatus": "been"
          },
          {
            "id": "22222222-BBBB-4BBB-8BBB-222222222222",
            "placeID": "fixture.balkan",
            "name": "Balkan Treat Box",
            "rating": 4.8,
            "types": ["restaurant"],
            "addedAt": "2025-11-15T12:00:00Z",
            "visitStatus": "none"
          }
        ]
        """

    /// restaurants.json as written by v1.1 (live on the App Store) — enrichment
    /// fields present on the first entry, absent on the second (never refreshed).
    static let restaurantsV1_1 = """
        [
          {
            "id": "33333333-CCCC-4CCC-8CCC-333333333333",
            "placeID": "fixture.union-loafers",
            "name": "Union Loafers Café and Bread Bakery",
            "rating": 4.7,
            "types": ["pizza_restaurant", "bakery", "restaurant"],
            "priceLevel": 2,
            "editorialSummary": "Contemporary haunt serving breads and pizzas.",
            "websiteURL": "https://www.unionloafers.com/",
            "reviewSummary": "People love the bread.",
            "lastRefreshedAt": "2026-04-10T09:00:00Z",
            "addedAt": "2026-04-09T17:45:00Z",
            "visitStatus": "been"
          },
          {
            "id": "44444444-DDDD-4DDD-8DDD-444444444444",
            "placeID": "fixture.olio",
            "name": "Olio",
            "rating": 4.5,
            "types": ["mediterranean_restaurant", "wine_bar"],
            "addedAt": "2026-04-20T20:15:00Z",
            "visitStatus": "none"
          }
        ]
        """

    /// restaurants.json as written by v1.2 — adds latitude/longitude.
    static let restaurantsV1_2 = """
        [
          {
            "id": "55555555-EEEE-4EEE-8EEE-555555555555",
            "placeID": "fixture.sado",
            "name": "Sado",
            "rating": 4.6,
            "types": ["sushi_restaurant", "japanese_restaurant"],
            "priceLevel": 3,
            "latitude": 38.6103,
            "longitude": -90.3123,
            "websiteURL": "https://www.sadostl.com/",
            "lastRefreshedAt": "2026-08-01T14:00:00Z",
            "addedAt": "2026-07-04T19:00:00Z",
            "visitStatus": "none"
          }
        ]
        """

    /// lists.json as written by v1.2 (first version with lists) — one Smart Sort
    /// list and one user-created list (no smartCategory key).
    static let listsV1_2 = """
        [
          {
            "id": "66666666-FFFF-4FFF-8FFF-666666666666",
            "name": "Coffee Shops",
            "iconName": "cup.and.saucer.fill",
            "restaurantIDs": [
              "33333333-CCCC-4CCC-8CCC-333333333333",
              "55555555-EEEE-4EEE-8EEE-555555555555"
            ],
            "smartCategory": "coffee",
            "createdAt": "2026-08-08T10:00:00Z"
          },
          {
            "id": "77777777-ABAB-4ABA-8ABA-777777777777",
            "name": "Date Night",
            "iconName": "list.bullet",
            "restaurantIDs": ["55555555-EEEE-4EEE-8EEE-555555555555"],
            "createdAt": "2026-08-08T11:30:00Z"
          }
        ]
        """
}
