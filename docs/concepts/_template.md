# <Concept name>

**What**: Lead with the *problem the concept exists to solve*, not the API surface.
What goes wrong without it, and why isn't it handled for you? Then the mechanism.
Assume an experienced platform/DevOps engineer who is newer to iOS/Swift — explain
the framework and language specifics. A table or short list is fine if the concept
has several parts.

**Why here**: Two angles, both worth having. The general one: why this matters for
an app of this shape at all. The specific one: what it couples to *in this
codebase* — which other file's decisions it constrains, what breaks if they drift.
Include the design reasoning behind the current choice, not just the choice.

**Where**: `path/File.ext:line` — pointers to where it lives in this codebase.

**Gotchas**: 1–2 bullets max. Only real ones — the thing that bites in six months.

**Deeper**: One link to authoritative docs or the best article.
