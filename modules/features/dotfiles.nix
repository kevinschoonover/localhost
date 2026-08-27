{ ... }:
{
  flake.nixosModules.dotfiles = { ... }:
  let
    dotfilesPath = "/home/kschoon/git-local/kevinschoonover/localhost/dotfiles";
    claudePath = "${dotfilesPath}/claude";
  in
  {
    system.activationScripts.dotfiles = ''
      mkdir -p /home/kschoon/.config

      # Symlink .config/<app> directories (stow layout: <app>/.config/<app>)
      for app in nvim kitty; do
        ln -sfn "${dotfilesPath}/$app/.config/$app" "/home/kschoon/.config/$app"
      done

      # Symlink individual dotfiles
      ln -sf "${dotfilesPath}/tmux/.tmux.conf" /home/kschoon/.tmux.conf
      ln -sf "${dotfilesPath}/git/.gitconfig" /home/kschoon/.gitconfig

      # Agent config. Only the always-on layer and our own skills/agents are
      # tracked; transcripts, credentials and caches stay out of the repo.
      # ~/.agents is the shared store both Claude homes read from, and the
      # skills.sh CLI writes opencode's copy directly.
      mkdir -p /home/kschoon/.claude /home/kschoon/.claude-home /home/kschoon/.agents/skills

      for h in .claude .claude-home; do
        ln -sfn "${claudePath}/claude/CLAUDE.md"     "/home/kschoon/$h/CLAUDE.md"
        ln -sfn "${claudePath}/claude/settings.json" "/home/kschoon/$h/settings.json"
        ln -sfn "${claudePath}/claude/rules"         "/home/kschoon/$h/rules"
      done

      ln -sfn "${claudePath}/agents/agents"           /home/kschoon/.agents/agents
      ln -sfn "${claudePath}/agents/.skill-lock.json" /home/kschoon/.agents/.skill-lock.json
      ln -sfn "${claudePath}/agents/sync-config.sh"   /home/kschoon/.agents/sync-config.sh

      # Skills we wrote. Registry skills are restored from .skill-lock.json.
      for skill in ${claudePath}/agents/skills/*/; do
        ln -sfn "$skill" "/home/kschoon/.agents/skills/$(basename "$skill")"
      done

      # One plugin store; enablement stays per-home in settings.json.
      if [ ! -L /home/kschoon/.claude-home/plugins ]; then
        ln -sfn /home/kschoon/.claude/plugins /home/kschoon/.claude-home/plugins
      fi

      # Fix ownership
      chown -h kschoon:users /home/kschoon/.config/{nvim,kitty}
      chown -h kschoon:users /home/kschoon/.tmux.conf /home/kschoon/.gitconfig
      chown -h kschoon:users /home/kschoon/{.claude,.claude-home}/{CLAUDE.md,settings.json,rules}
      chown -h kschoon:users /home/kschoon/.agents/{agents,.skill-lock.json,sync-config.sh}
    '';
  };
}
