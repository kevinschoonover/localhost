---
name: babysit
description: "Watch a PR through to ready-for-review: green CI, a two-reviewer TigerStyle pass, PHI-gated verification artifacts, one batched bot review, comment resolution, then squash and mark ready."
disable-model-invocation: true
---

Babysit the PR: the checks that run **after** implementation, carrying the PR from "code written" to "ready for review." Work the steps in order; each ends on the completion criterion in **bold**.

Two orderings the steps encode, and neither is negotiable:

- Verification artifacts are captured (step 5) once your own code changes are done, and published before any reviewer — bot or human — is invited in. The **captured SHA** travels with them: every later fix that moves HEAD recaptures the paths it touched, and step 10 checks the tree before the PR goes ready. An artifact of superseded code is worse than no artifact — it shows behaviour that no longer exists.
- Bots (CodeRabbit, Copilot) are external events — **batch**, never react per-fix. One bot pass per PR, fired at step 7, last of the reviewers: by then CI is green, your own findings are fixed, and the Verification comment is on the PR for the bots to read.

Every step is also **proportionate** to the diff in front of you. The work a step demands scales with what the change can break: a diff that alters no user-visible behaviour — tests, CI, infra config, a rename — evidences itself with its own run output, not with invented UI states, and a step whose subject the diff doesn't contain is recorded as not applicable rather than manufactured. Proportionate is not permission to skim: a step that does apply is worked in full.

## 1. Rebase onto base

Check the branch's position first: `gh api repos/{owner}/{repo}/compare/{base}...{head} --jq '{ahead:.ahead_by,behind:.behind_by}'`. If `behind` is 0 the branch already sits on current base — say so and move to step 2. A force-push that changes nothing costs a full CI cycle and throws away check results you are about to need.

Otherwise rebase onto the latest base, resolve any conflicts with the `resolving-merge-conflicts` skill, and force-push.

**Done when** the branch is on top of the current base with no conflicts — either because `behind` was already 0, or because the rebase is pushed.

## 2. CI green

Make every CI check pass on the PR head. Read the failures, fix the cause, push, and re-check — don't stop at the first green run if others are still pending.

A check reported as `skipping`, `neutral`, or `cancelled` by a workflow condition is a pass for this purpose — `deploy` gated behind a merge is the usual case. Read the condition that skipped it, confirm it was meant to skip on a PR, and move on; don't chase it into a green tick it will never show.

**Done when** `gh pr checks` shows nothing failing and nothing pending, with each non-passing check accounted for by the workflow condition that skipped it.

## 3. Two-reviewer code review

Launch both reviews in a single message, one subagent each, so neither pollutes the other's context:

- **Subagent A — `/code-review`.** Run its full process (Standards axis and Spec axis) against the diff. Standards carries three sources, all of them: the repo's own documented standards, that skill's smell baseline, and the entire TigerStyle spec. The subagent **reads `TIGERSTYLE.md` in this skill's directory itself** (`/home/kschoon/.claude/skills/babysit/TIGERSTYLE.md`) — pass the path, never a summary; a summarised spec reviews against a spec that doesn't exist. Require its report to name every TigerStyle section with a verdict, so a skipped section is visible.
- **Subagent B — a second, independent lens on the same diff.** Take the best reviewer this environment actually offers, in this order:

  1. **Running in Claude Code:** its built-in `/code-review` is the deepest available — a find-then-verify pass with its own confidence filter. It is hard-disabled for model invocation, so you cannot dispatch it: ask the user to type `/code-review` (or `/code-review ultra` for the multi-agent cloud pass, which is billed) and work from what it returns. If they decline or the diff does not warrant it, fall through.
  2. **Otherwise:** brief a plain subagent to review from the angles Subagent A does not cover — correctness and edge cases, security and data handling, performance, test adequacy, and API/contract compatibility. Require a confidence score and a stated reason per finding, and have it report only what it is at least 80% confident in; that threshold is what makes the findings worth reading. **Return the findings, do not post them** — step 6 has yet to publish, and the PR gets one Verification comment, not a review comment from inside a babysit run.

  Whichever route you take, do not run Subagent A's skill here as well. The same process twice is one reviewer, and this step needs two.

If a dispatch comes back refused rather than reviewed — a skill that can't be model-invoked, a tool the environment doesn't provide — name the blocker to the user and let them run that reviewer themselves. Reconstructing a review's process from memory is the one thing to avoid: an improvised review reports whatever the agent happened to think of.

TigerStyle is the house spec, not the top of the hierarchy. Three precedence rules bind it, and Subagent A gets them in its brief:

- **The repo's tooling wins.** Where a formatter, linter, or compiler already decides the question — indentation, line width, brace style, import order, formatting of any kind — the tool's configured answer is correct and the TigerStyle section reads `n/a — enforced by <tool>`. This repo has `prettier.config.js` and `eslint.config.js`; a finding that reformats what Prettier formats is noise.
- **The repo's language wins its own conventions.** TigerStyle was written for Zig. Where it collides with the idiom of the language in the diff — its casing, its module layout — the language's convention holds.
- **The task's own dependencies aren't debt.** "Zero dependencies" flags a dependency nobody asked for. A tool the change exists to add — a test runner, a framework the issue specified — is the point of the diff, not a violation.

A section can therefore come back `pass`, `violated`, or `n/a` with the reason. What it may not come back as is absent.

Alongside the two reports, scan the diff itself for anything that should never have been committed: a real credential, a populated `.env`, a live API key or token in a fixture, a connection string, a private key. Only the diff — pre-existing secrets in the repo are a separate conversation with the user, not a babysit fix.

**Then sweep for tombstones: the diff must read as the final state, not the route you took to it.** Anything you changed twice while working the branch — a comment rewritten after a review finding, an identifier renamed, a decision reversed — leaves text behind describing a state that existed only between your own commits. Inline the correction rather than layering it: assert the rule that holds now, keep the reasoning, drop the step. Grep the **added** lines for the tells — `first cut`, `was wrong`, `previously`, `used to`, `no longer`, `now instead of` — and for the quieter kind: counts that drifted as the branch grew ("both providers" once there are three), identifiers you renamed mid-branch still named in prose, and docs citing a command, endpoint or flag the code stopped using.

The distinction that decides each case is **where the superseded state lived**. Text explaining what replaced something that exists on the **base branch** is history a reviewer needs — keep it, that is the change's rationale. Text explaining what replaced something you **introduced and then changed on this branch** is archaeology about a design nobody shipped, and it is worse than noise twice over: it argues for the current choice against an alternative that never existed, and a squash-merge discards the commits that gave it context while leaving the comment in the tree forever.

Then work both reports: fix what's valid, and for each finding you reject write the reason it doesn't apply. **Batch** the fixes into a single push.

**Done when** every finding from both reports is fixed or has a written rejection reason, Subagent A's report carries `pass`, `violated`, or `n/a`-with-reason for every TigerStyle section, the diff carries no committed credential, the diff describes only the state it ships with no intra-branch archaeology, and the fixes are pushed as one push.

## 4. Cross-reference sibling PRs

List the other open PRs and read the ones that can bear on this diff: any that touch files this PR touches, and any carrying review feedback about a pattern this PR also uses. A PR sharing no files and no pattern with yours is ruled out from the list alone — record it and move on rather than reading it through.

**Done when** every open PR is either read for applicable feedback or ruled out by name, whatever applied is applied here, and any resulting fixes are pushed.

## 5. Capture verification artifacts

Your own code changes are settled — capture against this HEAD and record the SHA. Every later step checks artifacts against it.

Drive the change in the real app and capture what a reviewer would otherwise have to run themselves. Reuse the repo's own harness before hand-driving anything: if it has Playwright, Cypress, or a comparable browser suite, its report, trace, and video already are the artifact, and any flag it offers for retaining traces on a pass is the cheapest capture in the run. Only where no harness covers the path do you launch the app with the `run` skill and drive it through `claude-in-chrome`. Artifacts stay local until they clear the gate in step 6; nothing is posted from this step.

Run against **seed or synthetic data**, in a local or sandbox environment, with a fixture account whose name, DOB, and member ID you chose yourself. Screenshots of production data are the expensive path — they force redaction later, and redaction is where leaks happen. Choose the data before you capture, not after.

Enumerate the paths from the diff — the behaviour **this change** alters, not the app's whole surface — then capture one artifact each:

- **Happy path** — the change doing its job, end to end.
- **Each error path the diff itself creates or changes** — the branches you can point at in the diff: a validation it adds, an authorisation it tightens, a failure or timeout it now handles, an empty state it now renders. An error path the change never touches belongs to the suite, not to this PR.

Where the diff alters no user-visible behaviour, the artifact is the change's own output — the test report and traces for a test change, the plan or dry-run for infra, the command transcript for a script — and there are no UI paths to enumerate. Say that in the comment rather than staging a screenshot to fill the row.

Medium by path type: screenshot per state for UI; video or an ordered screenshot sequence for multi-step flows; a fenced text capture (command + output) for CLI, API, migration, and worker paths. Write them to a scratch directory outside the repo working tree.

**Done when** every enumerated path — happy and each error path — has an artifact on disk captured at the recorded SHA against seed data, and each artifact's file path is recorded against the path it evidences.

## 6. Clear the PHI gate, then publish

Publishing is one-way: a GitHub comment can be deleted but its uploaded asset URLs keep serving, and a committed artifact survives in git history after the file is removed. So the gate runs before the upload, on every artifact — images frame by frame, video scrubbed end to end including transient states, text captures line by line.

The leak taxonomy — identity, clinical, financial, secrets, and capture surroundings — lives in the global PHI rule in `~/.claude/CLAUDE.md`, which applies continuously from the first commit onward. **It is deliberately not restated here.** By the time a run reaches this step the code is already committed and pushed, so a taxonomy that first appears at step 6 arrives after most of the surface it was meant to protect. Read that rule and apply it to every artifact.

Launch a subagent for the gate whose whole job is finding leaks. What this step adds beyond the global rule is the *artifact* surface: captures leak through their **surroundings** far more often than their subject — the URL bar, a neighbouring tab, an OS notification, the signed-in avatar, a devtools pane, scrollback above the command you meant to show.

If the gate finds PHI that originated in the **diff rather than the capture**, the leak is already in git history. Stop, tell the user, and treat it as an incident — redacting a screenshot does nothing about a fixture committed three commits ago.

For anything found: recapture against seed data if that's cheap, else redact **irreversibly** — burn the box into the pixels and re-encode the video, replace the string in the text rather than truncating it, and never ship an overlay or blur that the original survives underneath. Delete the pre-redaction original from the scratch directory.

Only then publish, as one **Verification** comment on the PR — the captured SHA, then a row per path with steps run, expected, observed, and the artifact rendered in the comment. The artifacts themselves stay out of the repository: no commit, no artifact branch, nothing that lands in git history.

Default to a **GitHub attachment**, which is what the web UI's drag-and-drop produces: a `user-attachments` URL whose visibility inherits the repo, so on a private repo only people with repo access can view it. Images embed inline, `.mp4`/`.mov`/`.webm` render as an inline player from a bare URL on its own line, anything else becomes a download link. Caps: 10MB per image or video, 100MB for video on a paid org plan, 25MB other files — which is why step 5 prefers a short clip or a screenshot sequence.

Two ways to get the attachment, in order:

1. **`claude-in-chrome` on the authenticated session** — attach through the comment box's file input. Preferred: it rides the browser session you already have and never touches a credential.
2. **Replicate the drag-and-drop flow yourself** — for headless and background runs with no browser to drive. Four requests: pull the repo page's `uploadToken`, ask `/upload/policies/assets` for a presigned S3 policy, POST the file to S3, PUT the callback to finalise, then render `![name](href)` for an image or the bare `href` alone on its line for a video. Read the current wire details at run time from [`drogers0/gh-image`](https://github.com/drogers0/gh-image) — `documentation/github-image-upload-flow.md` for the shape, `internal/upload/` for exact fields, header, and ordering. These are internal GitHub endpoints that change without notice, so read them fresh rather than trusting a recipe cached anywhere; don't install the extension, write the flow in the repo's primary language and keep the script out of the product repo.

   Two things this route needs and one it forbids. It needs the numeric repo ID (`gh api repos/{owner}/{repo} --jq .id`) and write access — a 200 repo page with no `uploadToken` means either no write access or an org enforcing SAML SSO, which the user clears at `https://github.com/orgs/{owner}/sso` in a browser. It authenticates by **`user_session` cookie, never a PAT**: that cookie is unscoped and grants full account access, so treat it as a password — take it live from the user's session, never print, log, commit, or comment it, and if an unattended runner ever needs one, ask the user for a dedicated bot account rather than their personal session. If the flow breaks mid-run, fall through to the routes below instead of debugging it inside a babysit run.

Fall back when the attachment route is unavailable, or when an artifact could not be captured wholly against seed data and you want a host where deletion genuinely revokes:

3. **Text captures inline, plus local file paths** for the media — last resort. Say in the comment which paths have no visual evidence, and offer the user the capture files directly.

If none of these work, ask the user where artifacts should live rather than falling back to the repository.

Dead ends to skip: a PAT cannot drive `/upload/policies/assets` — that endpoint takes a session cookie, which is why route 2 exists and why `gh api` won't do it; `raw.githubusercontent.com` embeds break on private repos, where those URLs are signed and expiring; and a secret gist is unlisted but unauthenticated, so anyone holding the URL reads it — it never carries a verification artifact.

**Done when** every artifact has been through the gate with its findings listed, whatever was found is recaptured or irreversibly redacted with the originals deleted, and one Verification comment naming the captured SHA lets a reviewer judge every path without running code.

## 7. Bot review on the published PR

Now trigger CodeRabbit and Copilot — once, against the HEAD the Verification comment names. The comment is already on the PR, so point the bots at it.

Trigger CodeRabbit with a `@coderabbitai review` comment, and Copilot by requesting it as a reviewer (`gh api repos/{owner}/{repo}/pulls/{n}/requested_reviewers -f 'reviewers[]=copilot-pull-request-reviewer[bot]'`, or `gh pr edit --add-reviewer` where that resolves).

Establish first whether each bot is actually installed on this repo — a repo with no CodeRabbit app answers a trigger comment with silence, not a review. If one isn't there, record it as unavailable and carry on with the other; don't wait on a review that cannot arrive, and don't install an app on the org's behalf.

If CodeRabbit is rate-limited, read the reset time and schedule the review for after the limit clears rather than skipping it. If it needs credentials, copy the base `.env` from the core repo.

**Done when** each bot has either reviewed that HEAD, a review scheduled after a known rate-limit reset, or a recorded reason it is unavailable on this repo.

## 8. Resolve bot comments

Launch a subagent to go through every CodeRabbit and Copilot comment. For each: if the point is valid, fix it; if not, reply with the reason it doesn't apply. Then reply to and resolve the addressed threads in the PR.

**Batch** these fixes into one push and leave the bots alone afterwards — re-trigger only if a fix rewrote the approach or added files the bots never saw.

A fix here moves HEAD past the captured SHA. Recapture the paths it touches, run them through step 6's gate, and update the Verification comment with the new SHA.

**Done when** every open bot thread has a fix-or-reply and is resolved — none left untouched — the fixes are pushed as one push, and any path whose behaviour changed has a fresh gated artifact.

## 9. Resolve human comments

Go through every human reviewer comment separately — these outrank bot comments, so give each one full weight and never dismiss it as noise. For each: if valid, fix it; if you disagree or it needs a decision from the reviewer, reply with your reasoning and leave the thread for them rather than resolving it yourself. Resolve only the threads you've fully addressed.

Recapture as in step 8: any fix that changes observable behaviour gets a fresh gated artifact and a Verification comment carrying the new SHA.

**Done when** every human thread has a fix or a substantive reply, each addressed thread is resolved, and any path whose behaviour changed has a fresh gated artifact.

## 10. Squash and mark ready

A reviewer opening this PR reads the description before anything else, so it has to say what changed and why, and link the issue or spec it came from. Write it if it's empty, and correct it if the change outgrew it — the Verification comment evidences behaviour, it does not explain intent.

Re-run step 3's **tombstone sweep** over the added lines before squashing, and over the description too. Step 3 ran before the bot and human fix rounds, and those rounds are the ones most likely to have left archaeology: a finding fixed in step 8 often rewrites a comment written in step 3, and the description accumulates the same way — the "Merging" guidance in particular goes stale the moment a single-concern PR grows a second concern. Squashing is also the last moment the intermediate commits exist to give such a comment context.

Squash the branch by **concern**, not to a fixed count: one logical change per commit in conventional format, which is a single commit for a single-concern PR and several when the PR genuinely spans concerns — the same rule TigerStyle's own commit section states. Squashing unrelated concerns together buries them in `git blame`.

Squashing rewrites the SHA but not the tree, so check the artifacts against the tree: `git diff <captured-sha> HEAD` must come back empty. If it doesn't, the code moved after capture — recapture the affected paths through step 6 before marking ready.

Then mark the PR ready for review. If design questions remain for the user, surface them and stop here — leave the PR as a draft.

**Done when** the description states what and why with its issue linked, each commit is one concern in conventional format, `git diff <captured-sha> HEAD` is empty, `gh pr checks` is green on the final HEAD, and the PR is marked ready — or the open design questions are surfaced to the user.
