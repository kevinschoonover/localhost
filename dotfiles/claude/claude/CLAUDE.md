# Working agreement

Kevin — senior engineer at CrowdHealth (healthcare; assume PHI is near). Primary stack TypeScript/Node and Rails; NixOS.

## Code

- **Simple, type-safe, debuggable** — in that order, every time. Simplicity is the hardest revision, not the first attempt.
- **Handle every error.** No empty catch, no swallowed rejection, no floating promise. Rethrow with context or handle it.
- **Bound everything** — every loop, retry, queue, and pagination carries an explicit limit. No unbounded `while`.
- **Enforce constraints with types, not comments.** No magic numbers or strings. A type assertion is not validation.
- **Zero technical debt.** Solve it now; the second chance may not come.
- **Comments say why, not what.**

## Tests

Every behaviour change ships tests for **valid input, invalid input, and valid-becoming-invalid** — the boundary and the transition across it. A happy-path-only test does not count as a test. Every bug fix starts with a failing test that reproduces it. Use `/tdd` at pre-agreed seams; confirm all the seams in one question, not one per test.

The full TigerStyle spec is at `~/.claude/skills/babysit/TIGERSTYLE.md`. It is a **review** artifact — do not read it during implementation; `/implement-tigerstyle` carries the write-time subset.

## Evidence

**Ground every claim in an artifact the code actually produced.** "It works", "the flow is correct", "this should handle X" are claims, not evidence — mine as much as a subagent's. Run the thing and show what came back.

- **Web UI** — drive it (Playwright/Cypress if the repo has a harness, else the `run` skill + `claude-in-chrome`) and capture the real screens, including the error and empty states the change creates. Not a description of what the screen would show.
- **CLI / worker / migration** — run it end to end and paste the actual command and output.
- **API** — real request, real response body, real status code.
- **Library / pure logic** — the test run output.

Use **synthetic or seed data in a local or sandbox environment**, with fixture identities you chose. Ask before touching real data — never assume approval. Capture as you build, not at the end: an artifact is how you find out you were wrong while it is still cheap to fix. If a path can't be exercised, say so plainly rather than describing the behaviour as if you had seen it.

## PHI

This is a healthcare codebase. **Check before every commit, every push, every paste into an issue or PR, and every upload — not at review time.** Once it is pushed or published the leak has happened; a later deletion does not revoke it, and git history and uploaded asset URLs both outlive the delete.

Hunt these, in code, fixtures, seeds, test data, snapshots, SQL, logs, error messages, Sentry context, CI output, commit messages, screenshots, and terminal captures:

- **Identity** — member or patient name, DOB, SSN, member/subscriber/claim ID, MRN, address, phone, email, photo, account number.
- **Clinical** — diagnosis, procedure, medication, provider name, visit date, care request or bill detail.
- **Financial** — card or bank digits, payment token, invoice.
- **Secrets** — bearer or JWT in a URL, header, or devtools pane; API key; `.env` contents; connection string; cookie.
- **Surroundings** in any capture — URL query params and path IDs, tab titles, other open tabs, bookmarks, OS notifications, the signed-in avatar, devtools panes, shell history and prompt, log lines scrolled past.

Rules that follow from it:

- **Synthesise, don't sample.** Fixtures and test data get identities you invented, never a row copied from production. Real data pulled "just to check" is how it ends up committed.
- **Never paste a production query result** into code, a comment, a commit message, an issue, or a PR. Describe the shape instead.
- **Redaction is irreversible or it isn't redaction** — burn the box into the pixels, re-encode the video, replace the string. An overlay the original survives underneath is not redacted. Delete the pre-redaction original.
- If you find PHI **already committed**, stop and tell me before pushing. If it is already pushed, say so immediately — that is an incident, not a cleanup.

## Delegating to subagents

- **Sonnet by default.** Opus only when the hard thinking *is* the task — adversarial review where missing a defect is expensive, or ambiguous design calls. If the hard thinking is already in the brief, Sonnet executes it fine. Opus subagents burn the weekly budget fast.
- **The manager owns the metric, not the subagent.** Write the validation or measurement script yourself, run it, check it by hand against a known answer, *then* hand it over. If you cannot write the metric, the task is not specified well enough to delegate. Supply the measurement, not just the goal — "prove X didn't change" invites an invented method; "regenerate to a fresh dir, `sha256sum` both sides, report differing names" does not.
- **Treat a subagent's self-reported pass/fail as a claim, not evidence.** Re-run the metric yourself before believing it.
- **Commit before dispatching any review subagent.** Subagents share the parent's worktree and can silently `git checkout` away uncommitted edits. Tell review agents: read-only, no `git checkout`/`restore`/`stash`. Re-check `git status --short` after one finishes.

## Sessions

**One session, one task.** Prefer `/clear` at a task boundary over `/compact` — `/compact` re-reads the whole conversation and is expensive; `/clear` costs nothing. Session cost grows with the square of session length. When resuming, read the handoff in `~/.claude/handoffs/` rather than reconstructing context by re-reading the repo. After two failed corrections, clear and re-prompt instead of correcting a third time.

## Tools

- **Read files with `Read`, not `cat`/`head`/`tail`.** It is scoped, cheaper, and does not spend a shell round trip. Reach for Bash for file contents only when a pipeline genuinely needs it (counting, filtering across many files).
- **Offer choices with `AskUserQuestion`, not prose.** Any time you present 2+ options, put them in the tool rather than writing a lettered list — a lettered list costs a round trip to answer and loses the structure.
- **Never delete or archive a worktree with unpushed commits.** Push the branch first, always. If the branch is not worth pushing, say so and confirm before discarding it.

## Environment

- **Push over SSH, not HTTPS.**
- **Query prod via MCP, not psql.** A "classifier temporarily unavailable" message is a transient outage, not a denial — retry rather than routing around it.
- Missing a tool? Try `nix-shell`, or check `flake.nix`.
- Write scripts in the project's primary language, not shell — portable, type-safe, works for the whole team.
