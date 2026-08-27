---
paths:
  - "**/*.{ts,tsx,js,jsx}"
---
# TypeScript — TigerStyle at write time

TigerStyle is the house spec, not the top of the hierarchy. Three rules bind it:
**the repo's tooling wins** (where Prettier, ESLint, or `tsc` already decides — indentation, line width, brace style, import order — the tool's answer is correct and this file is silent); **the language wins its own conventions** (`camelCase` members, `PascalCase` types, `kebab-case` files — TigerStyle's Zig casing does not apply); **the task's own dependencies are not debt**.

## The three that matter most

- **Re-validate invariants after every `await`.** TigerStyle says functions run to completion without suspending. That *inverts* here: every `await` is a suspend point, so state read before one may be stale after it. Re-check what you relied on. This is a real TOCTOU class in Node.
- **Types carry the positive space; tests carry the negative space.** What is allowed should be unrepresentable-if-invalid in the type system; what is rejected is proven by a test. **Do not mechanically add assertions to hit TigerStyle's "two per function"** — that rule assumes a cheap `assert` and does not translate. Validate at trust boundaries instead.
- **Pass options explicitly at every call site.** Never rely on a library default — `fetch`, `JSON`, `Intl`, `Date`, and ORM defaults all drift under you.

## Shape

- Push ifs up, fors down: branching in the parent, non-branchy work in helpers. Parent holds state in locals; leaf functions are pure and compute a change rather than applying it.
- Exhaustive `switch` with a `never` default. Every `if` considers its `else` — handle or rule out both spaces.
- State invariants positively: `if (index < length)` beats `if (index >= length)`.
- Narrowest return type that works: `void` > `boolean` > `number` > optional > error union; a discriminated result beats a nullable. Dimensionality is viral through the call chain.
- `const` by default, declared where used. No aliases or duplicate variables — out-of-sync risk.
- Recursion over ASTs and trees is fine and idiomatic. Never recurse over user-controlled depth in a request path — bound it.

## Boundaries

- **Never spread an entity into a response or a log — enumerate the fields you expose.** This is TigerStyle's buffer-bleed rule translated, and here it is a PHI rule.
- No N+1. No `await` inside a loop over a collection — batch the network and database calls.
- **Two versions of the world.** Where a local row and an external provider resource (Stripe, Lago) both exist, never mutate one side alone. Validate preconditions loudly before the external write (raise, don't nil-out); after it, assert the response carries what the local row needs. Crash windows between the two writes need a deterministic retry path (canonical external id as idempotency key) or a reconciliation sweep.

## Numbers and names

- State division intent explicitly — exact, floor, or ceil. Never a bare `/` where rounding matters, never a bare `Date` diff across a DST boundary.
- `index`, `count`, `size` are distinct types with conversion rules; put units in names.
- Qualifiers last, descending significance: `latencyMsMax`, not `maxLatencyMs`. No abbreviations. Nouns over participles.
- Two same-typed arguments take a named/options object — a positional boolean is a defect factory.
- Long-form CLI flags (`--force`, not `-f`); single letters are for interactive use only.

## Dependencies

A new **runtime** dependency needs a named reason, a check of its maintenance and transitive weight, and a licence that clears review. Dev-only dependencies are cheap and need no ceremony. The dependency a task exists to add is the point of the diff, not a violation.
