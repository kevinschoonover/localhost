{ ... }:
{
  flake.nixosModules.shell = { pkgs, ... }: {
    environment.interactiveShellInit = ''
      eval "$(direnv hook bash)"
      export XDG_HOME_DIR="$HOME"
      export PNPM_HOME="$HOME/.local/share/pnpm"
      export PATH="$PNPM_HOME:$PATH"
      export PATH=$PATH:~/go/bin:~/.yarn/bin/:~/.local/share/pnpm
      export BROWSER=${pkgs.google-chrome}/bin/google-chrome-stable
      alias vim="nvim"
      alias update="pushd ~/git-local/kevinschoonover/localhost && nix flake update; popd && sudo nixos-rebuild switch"
      alias grep="rg"
      alias rb="sudo nixos-rebuild switch"
      alias cat="bat"
      alias ls="eza"
      alias tb="cd ~/git-local/bloominlabs/hostin-proj/test-bed"
      alias sse="source ~/.stratos/creds.sh && source ~/.stratos/setup_env.sh"
      alias blssh="vault ssh -host-key-mount-point=ssh-infra-host -mount-point=ssh-infra-client -role=root -mode=ca"
      function record {
        if [ -z "$1" ]; then
          wf-recorder -f ~/Videos/$(date +%Y-%m-%d_%H-%M-%S).mkv -g "$(slurp)"
        else
          wf-recorder -f $1 -g "$(slurp)"
        fi
      }
      alias discord="exec discord --use-gl=desktop --enable-features=UseOzonePlatform --ozone-platform=wayland"
      alias slack="exec slack --enable-features=UseOzonePlatform --ozone-platform=wayland"
      alias login="export VAULT_ADDR="https://vault.prod.stratos.host:8200"; vault login -method=oidc role=developer"
      alias token="export VAULT_ADDR="https://vault.prod.stratos.host:8200"; export NOMAD_ADDR="http://nomad-servers.prod.stratos.host:4646"; export NOMAD_TOKEN=\`vault read --format json nomad/creds/management | jq -r '.data.secret_id'\`"
      function we_are_in_git_work_tree {
       git rev-parse --is-inside-work-tree &> /dev/null
      }
      function parse_git_branch {
          if we_are_in_git_work_tree; then
          local BR=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD 2> /dev/null)
          if [ "$BR" == HEAD ]; then
              local NM=$(git name-rev --name-only HEAD 2> /dev/null)
              if [ "$NM" != undefined ]; then echo -n "@$NM"
              else git rev-parse --short HEAD 2> /dev/null; fi
          else echo -n $BR; fi; fi
      }
      function parse_git_status {
          if we_are_in_git_work_tree; then
          local ST=$(git status --short 2> /dev/null)
          if [ -n "$ST" ]; then echo -n " + "
          else echo -n " - "; fi; fi
      }
      function pwd_depth_limit_2 {
          if [ "$PWD" = "$HOME" ]; then echo -n "~"
          else pwd | sed -e "s|.*/\(.*/.*\)|\1|"; fi
      }
      flakify() {
        if [ ! -e flake.nix ]; then
          nix flake new -t github:nix-community/nix-direnv .
        elif [ ! -e .envrc ]; then
          echo "use flake" > .envrc
          direnv allow
        fi
        ''${EDITOR:-vim} flake.nix
      }
      COLBROWN="\[\033[1;33m\]"
      COLRED="\[\033[1;31m\]"
      COLCLEAR="\[\033[0m\]"
      export -f parse_git_branch parse_git_status we_are_in_git_work_tree pwd_depth_limit_2 flakify
      export PS1="$COLRED\$(parse_git_status)$COLBROWN\$(parse_git_branch) $COLRED>$COLCLEAR "
    '';
  };
}
