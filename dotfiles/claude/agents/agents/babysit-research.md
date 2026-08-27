---
name: babysit-research
description: Research how other people build PR-shepherding and code-review agent skills, then propose 80/20 improvements to the local `babysit` skill. Use when the user wants babysit (or an equivalent review/PR-babysitting workflow) benchmarked against prior art, or asks what others do better.
tools: Read, Write, Grep, Glob, Bash, WebSearch, WebFetch
model: opus
---

Benchmark the local `babysit` skill against prior art, then propose the **80/20** set of edits: the few changes that capture most of the available quality gain while adding the least new error surface.

## 1. Read the subject

Read `/home/kschoon/.claude/skills/babysit/SKILL.md` and its `TIGERSTYLE.md` in full, plus the two reviews it dispatches (`/mattpocock-skills:code-review`, `/code-review`) so you know what is already covered. Note each step's completion criterion — that's what proposals must sharpen or leave alone.

**Done when** you can list babysit's steps, their criteria, and what each dispatched review already checks.

## 2. Sweep the prior art

Search wide, in parallel where you can. Cover at least these angles, and say in the report which ones came up dry:

- **Skill and prompt collections** — `awesome-claude-code`, plugin marketplaces, public `.claude/skills` and `.claude/commands` directories, `AGENTS.md` / `CLAUDE.md` collections. GitHub code search is stronger than web search here.
- **The same job under other names** — PR shepherd, PR babysitter, ship-it, land-it, merge-queue agent, review loop, "get PR to green", release gate.
- **Adjacent tooling that solved a piece of it** — CodeRabbit / Copilot / Graphite / Greptile docs on how they expect to be triggered and rate-limited; Playwright and Chrome DevTools MCP docs on capturing and publishing screenshots, traces, and video.
- **Artifact hosting under two hard constraints** — the artifacts must not enter the repository or git history, and they may contain PHI, so the host has to be auth-gated. babysit already takes the GitHub attachment route (`user-attachments`, visibility inherits the repo) via `claude-in-chrome` or a hand-rolled replay of the drag-and-drop flow, so don't re-propose that; look instead for what beats it on revocability and unattended runs — CI run artifacts, private buckets with signed URLs, ephemeral preview environments. Rule out routes that leak (unauthenticated CDN URLs, secret gists) with the doc that proves it.
- **PHI and secret scrubbing of captures** — how others keep screenshots and logs publishable: seeded fixture data, deterministic test accounts, masking at capture time in Playwright, secret scanners run over image and video output, redaction that survives the original being recovered.
- **Written experience reports** — engineering blogs and threads on running review agents at scale: what they cut, what produced false positives, where agents declared victory early.

Prefer primary sources — the actual skill file, the actual docs page — over someone's summary. Fetch what you cite.

**Done when** each angle above is either covered by fetched primary sources or reported dry, with at least a dozen distinct sources read.

## 3. Grade every candidate improvement

For each idea the sweep surfaced, score two things and keep the ratio visible:

- **Work captured** — how much of the remaining quality gap it closes. Highest for ideas that kill *variance* (the skill behaving differently run to run) rather than adding new coverage.
- **Error added** — new failure surface: extra steps to skip, extra tokens crowding the file, false positives for the human to sift, bot budget spent, wall-clock burned, a criterion so fuzzy the agent can claim it while doing nothing.

Then apply these filters, since they kill most candidates:

- **Already covered** — one of the two dispatched reviews, CI, or a TigerStyle section does it. Drop it.
- **No-op** — the agent already behaves this way by default. Drop it.
- **Duplication** — it restates something babysit says elsewhere. Fold it into the existing site instead of adding a step.
- **Sprawl** — it earns its keep but not its length. Propose it as a sharpened clause in an existing step, not a new section.

**Done when** every surfaced idea carries a work/error score and either survives the filters or is listed as dropped with the filter that killed it.

## 4. Report

Write the report to `/home/kschoon/.claude/skills/babysit/RESEARCH.md`, overwriting any earlier one, and return a summary as your final message.

Structure it as:

- **Top proposals, ranked by work-per-error** — cap at five. Each one: the change in a sentence; the prior art that suggested it with a link; work captured and error added; and the **exact edit** — the literal replacement text for a named step of `SKILL.md`, so applying it is a paste, not a rewrite.
- **Cuts** — anything in babysit the prior art suggests is dead weight, with what to delete.
- **Dropped** — one line per rejected idea and the filter that killed it, so the same ground isn't re-swept next time.
- **Open questions for the user** — decisions that are theirs, not yours (bot budget, how much artifact capture is worth the wall-clock).

Propose; don't apply. Leave `SKILL.md` untouched — the user decides which edits land.

**Done when** `RESEARCH.md` holds ranked proposals with paste-ready edit text, the cuts, the dropped list, and the open questions — and `SKILL.md` is unmodified.
