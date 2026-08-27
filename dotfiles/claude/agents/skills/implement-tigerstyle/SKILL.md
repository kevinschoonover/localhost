---
name: implement-tigerstyle
description: "Implement a spec or set of tickets under TigerStyle write-time constraints."
disable-model-invocation: true
---

Run an `/implement` session — that skill owns the workflow spine (TDD at pre-agreed seams, typecheck often, single test files often, full suite once at the end, `/code-review`, commit). Do not restate or replace it.

`/implement` resolves either from the `mattpocock-skills` plugin or from the vendored copy in `~/.agents/skills/implement`, depending on which config home is active; both carry the same body. If it is unavailable in this environment, say so rather than improvising a substitute workflow — the spine is the point.

This skill adds one thing: TigerStyle applies **while the code is being written**, not only when it is reviewed. A violation caught at review costs a find pass and a fix pass on top of the write. Caught at write time it costs nothing.

## Read the spec first

Read `/home/kschoon/.claude/skills/babysit/TIGERSTYLE.md` before writing code. Read the file — never work from a summary of it, including the checklist below, which is a working subset and not the spec.

## The write-time subset

These are the rules that change what you type as you type it. Hold them while writing; the rest of the spec is for review.

- **Types carry the positive space; tests carry the negative space.** What is *allowed* should be unrepresentable-if-invalid in the type system. What is *rejected* is proven by a test. In TypeScript the test suite **is** the assertion layer — so do **not** mechanically add `assert` calls to satisfy TigerStyle's "two assertions per function". That rule was written for a language with a cheap `assert` and does not translate; the number is dead, the intent survives here. Validate at trust boundaries; a type assertion is not validation.
- **Re-validate invariants after every `await`.** TigerStyle says functions run to completion with no suspend. That **inverts** in TypeScript: every `await` *is* a suspend point, so state read before one may be stale after it. Re-check what you relied on. This is a real and hard-to-find TOCTOU class in Node.
- **Bound every loop, retry, queue, and pagination.** An explicit upper limit on each. No unbounded `while`. No recursion over user-controlled depth in a request path — bound the depth (recursion over ASTs and trees is fine and idiomatic).
- **Handle every error.** No empty catch, no swallowed rejection, no floating promise. `catch (e: unknown)` — rethrow with context or handle it. Operating errors are expected and handled; programmer errors crash.
- **Batch at the boundary.** No N+1. No `await` inside a loop over a collection — batch the network and database calls instead.
- **Never spread an entity into a response or a log.** Enumerate the fields you intend to expose. This is TigerStyle's buffer-bleed rule translated, and in this codebase it is a PHI rule.
- **Push ifs up, fors down.** Branching lives in the parent; helpers do non-branchy work. Parent holds state in locals; leaf functions are pure and compute a change rather than applying it. Exhaustive `switch` with a `never` default; every `if` considers its `else`.
- **Smallest scope, closest to use.** `const` by default, declared where used. No aliases, no duplicate variables — out-of-sync risk.
- **Simplest signature that works.** `void` beats boolean beats number beats optional beats error union; a discriminated result beats a nullable. Dimensionality is viral through the call chain.
- **Explicit options at the call site.** Never rely on a library default — `fetch`, `JSON`, `Intl`, `Date`, and ORM defaults all drift under you.
- **State division and date arithmetic explicitly.** Exact, floor, or ceil — never a bare `/`, never a bare `Date` diff across a DST boundary. `index`, `count`, `size` are distinct types with casting rules.
- **No magic numbers or strings.** Enums over booleans where a boolean would be read at the call site as a bare `true`.
- **Names carry units and meaning.** Qualifiers last, descending significance — `latencyMsMax`, not `maxLatencyMs`. No abbreviations. Nouns over participles. Two same-typed arguments get named/options form — a positional boolean is a defect factory.
- **Comments say why.** Self-documenting code first; comment the non-obvious block, the deviation, the foot-gun you could not eliminate. A test description states its goal and its method in one sentence.

## Tests

Every behaviour change ships tests for three cases: **valid input, invalid input, and valid-becoming-invalid** — the boundary and the transition that crosses it. A happy-path-only test does not count as a test. Every bug fix starts with a failing test that reproduces the bug.

## Precedence — three rules that bind TigerStyle

TigerStyle was written for Zig and this is a TypeScript codebase. It is the house spec, not the top of the hierarchy:

1. **Repo tooling wins.** Where Prettier, ESLint, or `tsc` already decides — indentation, line width, brace style, import order, any formatting — the tool's configured answer is correct. Do not hand-apply TigerStyle's 4-space/100-column rules against a configured formatter.
2. **The language wins its own conventions.** TypeScript's `camelCase` functions and `PascalCase` types beat TigerStyle's Zig casing. Recursion is idiomatic in TS for tree and AST work — prefer iteration with an explicit bound where practical, but do not contort a tree walk to avoid it.
3. **The task's own dependencies are not debt.** "Zero dependencies" flags a dependency nobody asked for. A library the ticket exists to add is the point of the work.

## Evidence, while you build

`/babysit` step 5 captures verification artifacts once the code is settled. That is too late to be *useful* — by then the artifact only confirms or embarrasses. Capture the same evidence **as each slice lands**, and step 5 becomes a publishing step rather than a discovery step.

The rule: **every claim about behaviour is grounded in an artifact the code actually produced.** "It works", "the flow is correct", "this should handle the empty case" are claims. Run it and show what came back.

Enumerate the paths **the diff changes** — not the app's whole surface — and exercise each:

- **Web UI** — drive the real app. Use the repo's own harness first: if it has Playwright, Cypress, or equivalent, its report, trace, and video *are* the artifact, and any retain-trace-on-pass flag is the cheapest capture available. Only where no harness covers the path, launch with the `run` skill and drive through `claude-in-chrome`. Capture the happy path **and each error, empty, and loading state this change creates** — those are the ones that ship broken.
- **CLI, worker, job, migration** — run it end to end; the artifact is the command and its actual output, fenced verbatim. For a migration, the dry-run or plan as well.
- **API / route** — a real request and the real response body and status, not a schema you believe it returns.
- **Library or pure logic** — the test run output, including the failing run that came first.

Rules that make the evidence trustworthy:

- **Synthetic or seed data, local or sandbox, fixture identities you chose yourself.** Ask before touching real or production data and wait for an answer — never assume approval. This is a healthcare codebase; a screenshot of real data is a leak that redaction only partly undoes, and choosing the data up front is cheaper than redacting after.
- **Exercise the flow, not the unit.** A green unit test is not evidence the flow works — wire-up, ordering, and integration are exactly what unit tests miss.
- **A run that did not happen is not evidence.** If a path cannot be exercised — no harness, no environment, an external dependency you cannot reach — say so plainly and name what is missing. Never describe behaviour as though you observed it.
- **Keep artifacts in a scratch directory outside the repo tree.** They do not get committed. Publishing happens in `/babysit` step 6, behind the PHI gate.
- **Re-run after every fix that touches the path.** A stale artifact showing superseded behaviour is worse than none.

## Done when

The implement skill's own completion criteria are met, the diff satisfies the write-time subset above, and every path the diff changes has a real artifact on disk with its file path recorded against the path it evidences — so that `/babysit` step 3 finds style violations rare rather than routine, and step 5 has only to gate and publish what already exists.
