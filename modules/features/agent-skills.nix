{ ... }:
{
  flake.nixosModules.agent-skills =
    { pkgs, ... }:
    {
      # Agent skills are installed by the skills.sh CLI into ~/.agents, which the
      # Claude Code homes symlink and opencode is written to directly. The CLI has
      # no self-update, so refresh them on a timer rather than by hand.
      systemd.user.services.agent-skills-update = {
        description = "Update globally installed agent skills (skills.sh)";
        documentation = [ "https://skills.sh/" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          # -g global scope, -y skip the scope prompt. Writes every agent target
          # recorded in ~/.agents/.skill-lock.json (claude-code, opencode, ...).
          ExecStart = "${pkgs.nodejs}/bin/npx --yes skills@latest update -g -y";
          TimeoutStartSec = "10m";
          # A failed update must never block anything: the installed versions keep
          # working, and the next timer firing retries.
          SuccessExitStatus = [
            0
            1
          ];
        };
      };

      systemd.user.timers.agent-skills-update = {
        description = "Weekly update of agent skills";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "Mon 09:00";
          # Catch up if the machine was off when the timer was due.
          Persistent = true;
          RandomizedDelaySec = "30m";
        };
      };
    };
}
