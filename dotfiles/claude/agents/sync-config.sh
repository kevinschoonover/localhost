#!/usr/bin/env bash
# Re-sync shared engineering rules from ~/.claude to ~/.claude-home and opencode.
# Source of truth: ~/.claude/CLAUDE.md + ~/.claude/rules/*.md + ~/.agents/{skills,agents}
set -euo pipefail
S=~/.claude; H=~/.claude-home; O=~/.config/opencode

mkdir -p "$H/rules" "$H/agents" "$H/skills"
cp "$S/CLAUDE.md" "$H/CLAUDE.md"
cp "$S"/rules/*.md "$H/rules/"

for a in ~/.agents/agents/*.md; do
  n=$(basename "$a")
  ln -sfn "../../.agents/agents/$n" "$S/agents/$n"
  ln -sfn "../../.agents/agents/$n" "$H/agents/$n"
done

for d in ~/.agents/skills/*/; do
  n=$(basename "$d")
  [ -e "$S/skills/$n" ] || ln -sfn "../../.agents/skills/$n" "$S/skills/$n"
  [ -e "$H/skills/$n" ] || ln -sfn "../../.agents/skills/$n" "$H/skills/$n"
done

node -e '
const fs=require("fs");
const p=process.env.HOME+"/.config/opencode/AGENTS.md";
let t=fs.readFileSync(p,"utf8");
const claude=fs.readFileSync(process.env.HOME+"/.claude/CLAUDE.md","utf8");
let body=claude.replace(/^# Working agreement\n\n/,"")
  .replace(/\n## Sessions[\s\S]*?(?=\n## )/,"\n")
  .replace(/\n## Tools[\s\S]*?(?=\n## )/,"\n");
const START="<!-- shared-engineering-rules-begin -->", END="<!-- shared-engineering-rules-end -->";
const block=START+"\n<!-- Synced from ~/.claude/CLAUDE.md. Edit there, not here. -->\n\n"+body.trim()+"\n"+END;
t = t.includes(START) ? t.replace(new RegExp(START+"[\\s\\S]*?"+END),block) : t.trimEnd()+"\n\n"+block+"\n";
fs.writeFileSync(p,t);'

# Share the plugin store: one install cache, per-home enablement in settings.json.
if [ ! -L "$H/plugins" ]; then
  [ -e "$H/plugins" ] && mv "$H/plugins" "$H/plugins.backup.$(date +%s)"
  ln -sfn "$S/plugins" "$H/plugins"
fi

echo "synced: .claude -> .claude-home + opencode"
