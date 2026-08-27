# Agent configuration

Source-controlled configuration for Claude Code and opencode. Applied by
`modules/features/claude.nix`, which symlinks these into place on rebuild.

## Layout

- `claude/` — the always-on layer: `CLAUDE.md`, `settings.json`, `rules/`.
  Symlinked into both `~/.claude` and `~/.claude-home`.
- `agents/agents/` — custom subagents. Symlinked into `~/.agents/agents`, which
  both Claude homes read from.
- `agents/skills/` — skills written here, not installed from a registry.
  Everything else is reproducible from `.skill-lock.json`.
- `agents/.skill-lock.json` — the skills.sh manifest. `npx skills@latest
  experimental_install` restores every registry skill from it, so only our own
  need tracking.
- `agents/sync-config.sh` — propagates `~/.claude` to `~/.claude-home` and
  opencode.

## What is deliberately absent

Session transcripts, `history.jsonl`, `file-history/`, and `.credentials.json`
stay out — they hold OAuth tokens and PHI. See `.gitignore`.

Plugins are not tracked either: they are managed installs with their own cache
and lockfiles. `settings.json` records which are enabled; Claude Code installs
them on demand.

## Restoring on a new host

1. `nixos-rebuild` applies `claude.nix`, creating the symlinks.
2. `npx skills@latest experimental_install` in `~/.agents` restores registry skills.
3. `systemctl --user status agent-skills-update.timer` confirms weekly updates are armed.
