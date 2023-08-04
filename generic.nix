{ config, pkgs, lib, ... }:

let
  unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
  # TODO: does not work during install because tailscale is not initialized
  # + you need certificate to even be able to access it
  internalCA = builtins.readFile (builtins.fetchurl {
    url = "https://vault.prod.stratos.host:8200/v1/internal/ca/pem";
    sha256 = "d69f2f83b9999d1462a5d25dba4cfafbfaf8569894d4d08f81d2f9878e1237a2";
  });
  # internalCA = builtins.readFile /home/kschoon/Downloads/pem;
in
{
  # Enable support for the YubiKey PBA
  boot.initrd.luks.yubikeySupport = true;

  # optimize the nixstore by symlinking identically derivations
  nix.autoOptimiseStore = true;
  # periodically trim the SSD
  services.fstrim.enable = true;
  # automatically garbage collect the nix store
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nixpkgs.config.allowUnfree = true;
  system.autoUpgrade.enable = true;
  security.pki.certificates = [ internalCA ];
  environment.variables.EDITOR = "nvim";
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    XDG_CURRENT_DESKTOP = "sway"; # https://github.com/emersion/xdg-desktop-portal-wlr/issues/20
    XDG_SESSION_TYPE = "wayland"; # https://github.com/emersion/xdg-desktop-portal-wlr/pull/11
    WLR_NO_HARDWARE_CURSORS = "1";
    # WLR_RENDERER = "vulkan";
  };

  # firmware updated
  # https://github.com/NixOS/nixos-hardware/tree/master/dell/xps/13-9380
  services.fwupd.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # services.openssh.enable = true;
  # services.openssh.listenAddresses = [{ addr = "100.120.192.102"; port = 2222; }];
  # users.users.kschoon.openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC32BCKLtDkwrVviZZClZSJ5AO2XeWaFUp7CLOJgPSWp0JTck4aGx9U8zjtjo1xzTRqtm5R+ftu6MBbgpEEo2z5NQoBPSOa89AyeszRMDFgHboNNrJ8sn6+ToLpzWJKXnOM0BhNIdbYXjVdROcKnf+/tiO9mj+tIn42iGppbmMKeO+BXvuMhkQV6FL9gJbxRDD6VI1hgOlHg0Ku2a8c8KKW3eiv9XtOc8kuDY68Yg/mPTY3wUgBqwqaq+HYo+gMEkWZefiG+JvlOw18cwx3fsr0CBVHgZsZIcSdQMNx5MkQx/+M8ZKnJzCHcGPRPCYdpwQOFxBLXDG2RI7sAcVw9be8K6RlLuEBmxrY8O/QtTHmkVlOjn+s5fyfK3GY5hnUV9+R1ao+EDoF9z2IGZSbypnK+gne+bGkq2J0CH4P6Hws8xgFIWefi06i7k03LcMnkDRTmifTrCvUCRSYxIrr+PthK4wDHUyqTCsWp7jfZ5TwynRR7vss593CIjJTrx+xrBiMYEWRXp13+PPl0qF2RpxfKesOu5nZsD7UmWv8FTy6GJocC0k+CHrnk4FAAuLETQPBHQkfJMqyRhvRAmoO4CpviTQ2pQEkIrC3AXJkLxxltpRidK/I4DTmW0mHcJiXzXvLmR/YWTDprWYEtXaSBHtFU5pt88wt/pO2RpIlOkWu0w== kschoon@honeypot" ];

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # ssh - 22 
  # remote buildkit - 8372
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 8372 ];

  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  services.resolved.enable = true;
  services.resolved.dnssec = "allow-downgrade";
  services.resolved.fallbackDns = [
    # cloudflare
    "1.1.1.1"
    "1.0.0.1"
    "2606:4700:4700::1111"
    "2606:4700:4700::1001"

    # google
    "8.8.8.8"
    "8.8.4.4"
    "2001:4860:4860::8888"
    "2001:4860:4860::8844"
  ];
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];

  # Set your time zone.
  time.timeZone = "America/Vancouver";

  fonts = {
    fonts = with pkgs; [
      nerdfonts
    ];
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "FiraCode Nerd Font";
    keyMap = "us";
  };

  # Sound settings
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;

    media-session.config.alsa-monitor = {
      rules = [
        {
          matches = [{ "node.name" = "alsa_output.*"; }];
          actions = {
            update-props = {
              "api.acp.auto-port" = false;
              "api.acp.auto-profile" = false;
              "api.alsa.use-acp" = false;
            };
          };
        }
      ];
    };
  };

  xdg = {
    icons.enable = true;
    portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-wlr
      ];
      gtkUsePortal = true;
    };
  };

  users.users.kschoon = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "networkmanager" "docker" ];
  };
  services.getty.autologinUser = "kschoon";

  environment.loginShellInit = ''
    if [ "$(tty)" = "/dev/tty1" ]; then
      exec sway --my-next-gpu-wont-be-nvidia >> ~/.sway.log 2>&1 
      # exec ${pkgs.kanshi}/bin/kanshi 2>&1 ~/.kanshi.log
    fi
  '';
  environment.sessionVariables.DEFAULT_BROWSER = "${pkgs.google-chrome}/bin/google-chrome-stable";
  environment.interactiveShellInit = ''
    # pnpm
    export PNPM_HOME="~/.local/share/pnpm"
    export PATH="$PNPM_HOME:$PATH"
    # pnpm end
    export PATH=$PATH:~/go/bin:~/.yarn/bin/:~/.local/share/pnpm
    export BROWSER=${pkgs.google-chrome}/bin/google-chrome-stable
    alias vim="nvim"
    alias update="sudo nix-channel --update nixos && sudo nix-channel --update nixos-unstable && sudo nix-channel --update nixos-hardware && sudo nixos-rebuild switch --upgrade"
    alias grep="rg"
    alias rb="sudo nixos-rebuild switch"
    alias cat="bat"
    alias ls="exa"
    alias tb="cd ~/git-local/bloominlabs/hostin-proj/test-bed"
    alias sse="source ~/.stratos/creds.sh && source ~/.stratos/setup_env.sh"
    alias blssh="vault ssh -host-key-mount-point=ssh-infra-host -mount-point=ssh-infra-client -role=root -mode=ca"

    alias discord="exec discord --use-gl=desktop"
    alias token="export NOMAD_TOKEN=\`vault read --format json nomad/creds/management | jq -r '.data.secret_id'\`"

    function we_are_in_git_work_tree {
     git rev-parse --is-inside-work-tree &> /dev/null
    }
   
    function parse_git_branch {
        if we_are_in_git_work_tree
        then
        local BR=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD 2> /dev/null)
        if [ "$BR" == HEAD ]
        then
            local NM=$(git name-rev --name-only HEAD 2> /dev/null)
            if [ "$NM" != undefined ]
            then echo -n "@$NM"
            else git rev-parse --short HEAD 2> /dev/null
            fi
        else
            echo -n $BR
           fi
        fi
    }
   
    function parse_git_status {
        if we_are_in_git_work_tree
        then
        local ST=$(git status --short 2> /dev/null)
        if [ -n "$ST" ]
        then echo -n " + "
        else echo -n " - "
        fi
        fi
    }
   
    function pwd_depth_limit_2 {
        if [ "$PWD" = "$HOME" ]
        then echo -n "~"
        else pwd | sed -e "s|.*/\(.*/.*\)|\1|"
        fi
    }
   
    COLBROWN="\[\033[1;33m\]"
    COLRED="\[\033[1;31m\]"
    COLCLEAR="\[\033[0m\]"
   
    # Export all these for subshells
    export -f parse_git_branch parse_git_status we_are_in_git_work_tree pwd_depth_limit_2
    export PS1="$COLRED\$(parse_git_status)$COLBROWN\$(parse_git_branch) $COLRED>$COLCLEAR "
  '';

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # cli 
    jq
    vim
    unstable.tmux
    wget
    htop
    unstable.git
    unstable.gh
    unstable.ripgrep
    unstable.fd
    unstable.exa
    unstable.delta
    unstable.bat
    unstable.croc
    step-cli
    unstable.pscale
    # unstable.mysql80
    unstable.nomad_1_6
    unstable.consul
    unstable.consul-template
    unstable.envconsul
    unstable.vault
    unstable.pulumi-bin
    dogdns
    unstable.packer
    unstable.google-cloud-sdk
    unstable.helix

    # passwords
    bitwarden
    bitwarden-cli

    # system-utils
    libnotify
    brightnessctl
    pamixer
    pavucontrol
    unzip
    vulkan-tools

    # gui 
    altair # graphql client
    insomnia # rest client
    unstable.minecraft
    unstable.prismlauncher
    # firefox
    # firefox-devedition-bin
    google-chrome
    google-chrome-dev
    unstable.discord
    unstable.wf-recorder

    spotify

    unstable.kitty

    unstable.earthly
    docker-compose

    # programming languages 
    gnumake
    unstable.go_1_20
    unstable.air # golang auto rebuilder
    unstable.delve # golang debugger
    unstable.poetry
    # pkgs.python39Packages.poetry
    # pnpm
    unstable.nodejs
    unstable.yarn
    gcc
    tree-sitter
    ctags
    # cargo
    binutils
    unstable.wrangler
    unstable.rustup
    unstable.ansible
    unstable.ansible-lint

    # lsps
    unstable.taplo-cli
    unstable.rust-analyzer
    unstable.ansible-language-server
    unstable.gopls
    unstable.marksman
    unstable.gotools
    unstable.terraform-lsp
    unstable.pyright
    unstable.stylua
    unstable.efm-langserver
    unstable.rust-analyzer
    unstable.sumneko-lua-language-server
    unstable.pkgs.nodePackages.prettier
    unstable.nodePackages.eslint_d
    unstable.nodePackages.json-server
    unstable.nodePackages.diagnostic-languageserver
    unstable.nodePackages.dockerfile-language-server-nodejs
    unstable.nodePackages.bash-language-server
    unstable.nodePackages.yaml-language-server
    unstable.nodePackages.typescript-language-server
    unstable.nodePackages.vscode-langservers-extracted
    unstable.rnix-lsp

    unstable.neovim
  ];
  virtualisation.docker.enable = true;
  virtualisation.docker.package = unstable.docker;
  virtualisation.docker.autoPrune.enable = true;

  security.pam.yubico = {
    enable = true;
    debug = false;
    mode = "challenge-response";
  };
  security.pam.yubico.control = "sufficient";

  programs.mtr.enable = true;
  programs.steam.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  hardware.pulseaudio.support32Bit = true;
  hardware.steam-hardware.enable = true;


  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  programs.sway = {
    enable = true;
    extraPackages = with pkgs; [
      xdg-utils
      swaylock
      swayidle
      waybar
      wl-clipboard
      mako
      alacritty
      dmenu
      bemenu
      grim
      slurp
      kanshi
    ];
  };

  # set my location to seattle for redshift seattle
  location.latitude = 47.6;
  location.longitude = 122.3;
  services.redshift = {
    enable = true;
    # Redshift with wayland support isn't present in nixos-19.09 atm. You have to cherry-pick the commit from https://github.com/NixOS/nixpkgs/pull/68285 to do that.
    package = pkgs.redshift-wlr;
  };

  programs.waybar.enable = true;

  hardware.opengl = {
    enable = true;
  };

  services.tailscale.enable = true;
  services.tailscale.package = unstable.tailscale;
}
