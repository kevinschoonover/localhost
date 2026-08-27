
# TigerStyle

## Design Goals

Safety, performance, developer experience. In that order. Readability = table stakes, means not end.

## Tone & Behavior

Flag error handling, edge cases, performance issues. Spot conflicts with existing patterns. Flag security concerns, data validation gaps.

## Engineering Principles

- Focus: debuggability, maintainability, readability, simplicity. No premature optimization.
- Enforce constraints with types, not comments/tests. No magic numbers/strings. Prefer enums over booleans where sensible.
- No deep nesting. Composition over inheritance.
- Remove dead code, unused deps.

## Simplicity

Simplicity not first attempt — hardest revision. Multiple passes, sketches, maybe throw one away. Spend thought upfront: design cost dwarfed by implementation and testing, then operation and maintenance. Hour of design worth weeks in production.

## Technical Debt

Zero technical debt. Do right first time — second time may not come. Problem solved in production many times more expensive than in implementation or design. Found showstopper (latency spike, exponential algorithm)? Solve now. Nothing slip through.

## Safety

Base: [NASA Power of Ten](https://spinroot.com/gerard/pdf/P10.pdf).

- Simple, explicit control flow only. No recursion — bounded executions stay bounded.
- Minimum of excellent abstractions, only if best fit for domain. Every abstraction risk leak.
- Limit everything. All loops, all queues: fixed upper bound. Fail fast. Loop that cannot terminate (event loop): assert it.
- Assertions detect programmer errors. Operating errors expected → handle. Assertion failures unexpected → crash. Assertions downgrade correctness bugs to liveness bugs; force multiplier for fuzzing.
  - Assert all arguments, return values, pre/postconditions, invariants. Minimum two assertions per function average.
  - Pair assertions: each property asserted on ≥2 code paths (e.g. before write, after read).
  - Split compounds: `assert(a); assert(b);` over `assert(a and b);`. Implication: `if (a) assert(b)`.
  - Assert relationships of compile-time constants — check design integrity before program run.
  - Golden rule: assert positive space (expected) AND negative space (not expected). Bugs live at valid/invalid boundary. Tests exhaustive: valid data, invalid data, valid-becoming-invalid.
  - Assertions ≠ substitute for understanding. Fuzzer prove presence of bugs, not absence. Mental model first → encode as assertions → explain in code and comments → fuzzer last line of defense.
- Declare variables at smallest scope. Minimize variables in scope.
- Hard limit 70 lines per function. Good shape: few parameters, simple return type, meaty logic between braces.
  - Centralize control flow: keep switch/if in parent function, move non-branchy fragments to helpers. ["Push ifs up, fors down"](https://matklad.github.io/2023/11/15/push-ifs-up-and-fors-down.html).
  - Centralize state manipulation: parent holds state in locals, helpers compute change not apply it. Leaf functions pure.
- All compiler warnings at strictest setting.
- Don't react directly to external events. Run at own pace: control flow stays yours, batching instead of context switch per event, bounded work per period.
- Split compound boolean conditions into nested `if/else`. Each `if`: consider matching `else` — handle or assert both spaces.
- State invariants positively. `if (index < length) { } else { }` beats `if (index >= length)`.
- Handle all errors. 92% of catastrophic failures = bad handling of non-fatal errors ([study](https://www.usenix.org/system/files/conference/osdi14/osdi14-paper-yuan.pdf)).
- Always say why. Rationale increase understanding, compliance, and share evaluation criteria.
- Pass options explicitly at call site — never rely on library defaults. Avoid latent bugs if defaults change.

## Performance

- Best time for 1000x wins: design phase, exactly when can't measure or profile. Mechanical sympathy — work with grain.
- Back-of-envelope sketches: four resources (network, disk, memory, CPU) × two characteristics (bandwidth, latency). Sketches cheap; "roughly right" land within 90% of max.
- Optimize slowest resource first (network → disk → memory → CPU), weighted by usage frequency — frequent cache miss can cost like fsync.
- Separate control plane from data plane. Amortize network, disk, memory, CPU costs by batching.
- CPU = sprinter: predictable, no lane changes, big enough chunks of work.
- Be explicit; don't lean on compiler. Extract hot loops into standalone functions with primitive arguments.

## Naming

- Get nouns and verbs just right. Great names = crisp mental model, show domain understanding.
- `CamelCase` for functions, variables, files. No abbreviated names (except primitive int in sort/matrix code). Scripts: `--force`, not `-f`; single-letter flags interactive only.
- Proper acronym capitalization (`VSRState`, not `VsrState`).
- Units/qualifiers last, descending significance: `latency_ms_max` not `max_latency_ms`. Groups and aligns related names.
- Infuse meaning: `gpa`/`arena` beat `allocator` — tell reader cleanup semantics.
- Related names same character count: `source`/`target` beat `src`/`dest` — `source_offset`/`target_offset` line up, symmetrical code easier to check.
- Helper called by one function: prefix with caller name — `read_sector()`, `read_sector_callback()`. Callbacks last in parameter list (invoked last).
- Order matters. Important things near top; `main` first. Structs: fields, then types, then methods. When in doubt: alphabetical.
- No overloaded context-dependent names — one term, one meaning.
- Nouns beat adjectives/participles: `replica.pipeline` beats `replica.preparing` — usable directly in docs, composes (`config.pipeline_max`).
- Two same-typed arguments: use named/options arguments. Nullable argument: name so `null` at call site is clear.

## Comments

- Self-documenting code over comments. Explain why, not what. Comment only when:
  - Block purpose not obvious (long or convoluted logic).
  - Deviating from standard/obvious approach.
  - Caveats, gotchas, foot-guns exist and can't be eliminated. First eliminate foot-gun or make obvious via code structure or type system: invalid boolean flag combos → enum.
- Comments = prose sentences (capital, full stop); end-of-line comments can be phrases.
- Tests: description at top with goal and methodology.

## Git Commits

- Conventional format: `<type>(<scope>): <subject>`, type = feat|fix|docs|style|refactor|test|chore|perf.
- Subject: 50 chars max, imperative mood ("add" not "added"), no period.
- Small change: one-line commit. Complex change: body explaining what/why (72-char lines), reference issues.
- Atomic commits (one logical change), self-explanatory. Different concerns → split commits.
- PR description invisible in `git blame` — not replacement for commit message.

## Cache Invalidation

- No duplicate variables, no aliases — out-of-sync risk.
- Shrink scope. Fewer variables at play → less chance wrong one used.
- Compute/check variables close to use. No variables before needed, none left after. Gap in time or space = semantic gap = bugs (POCPOU, cousin of [TOCTOU](https://en.wikipedia.org/wiki/Time-of-check_to_time-of-use)).
- Simple signatures and return types reduce call-site branches. Dimensionality viral through call chain: void beats bool, bool beats int, int beats optional, optional beats error union.
- Functions run to completion, no suspend — precondition assertions hold for whole lifetime.
- Guard against [buffer bleeds](https://en.wikipedia.org/wiki/Heartbleed) (underflow): unzeroed padding leaks data, breaks determinism.
- Newlines group resource allocation with matching cleanup — leaks easier to spot.

## Off-By-One

- Usual suspects: `index`, `count`, `size`. Treat as distinct types with casting rules. index → count: add one (0-based → 1-based). count → size: multiply by unit. Units in names.
- Show division intent explicitly: exact, floor, or ceil.

## Style

- 4-space indent. Hard limit 100 columns, no exceptions — fits two files side-by-side.
- Braces on `if` unless fits single line — defense against "goto fail;" bugs.
- Run the formatter.

## Dependencies & Tooling

- Zero dependencies apart from toolchain. Dependencies = supply chain risk, safety/performance risk, slow installs.
- Small standardized toolbox. Write scripts in primary language, not shell: portable, type safe, works for whole team.
- Tool missing? Try nix-shell or check flake.nix.
