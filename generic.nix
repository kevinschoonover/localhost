{ config, pkgs, lib, ... }:

let
  unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
  # TODO: does not work during install because tailscale is not initialized
  # + you need certificate to even be able to access it
  internalCA = builtins.readFile (builtins.fetchurl {
    url = "https://vault.prod.stratos.host:8200/v1/internal/ca/pem";
    sha256 = "42530935ac31693d2be69f6b64849d4e444c70f962f34a8ab742c92cc37c71cb";
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
  nixpkgs.overlays = [
    (import (builtins.fetchTarball "https://github.com/PolyMC/PolyMC/archive/develop.tar.gz")).overlay
  ];
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
  };

  # firmware updated
  # https://github.com/NixOS/nixos-hardware/tree/master/dell/xps/13-9380
  services.fwupd.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
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
      exec sway >> ~/.sway.log 2>&1 
      # exec ${pkgs.kanshi}/bin/kanshi 2>&1 ~/.kanshi.log
    fi
  '';

  environment.interactiveShellInit = ''
    alias grep="rg"
    alias rb="sudo nixos-rebuild switch"
    alias cat="bat"
    alias ls="exa"
    alias tb="cd ~/git-local/bloominlabs/hostin-proj/test-bed"
    alias sse="source ~/.stratos/creds.sh && source ~/.stratos/setup_env.sh"

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
    tmux
    wget
    htop
    git
    gh
    ripgrep
    exa
    bat
    croc
    step-cli
    nomad
    consul
    consul-template
    # envconsul
    vault
    unstable.pulumi-bin
    dogdns

    unstable.packer

    # passwords
    bitwarden
    bitwarden-cli

    # system-utils
    libnotify
    brightnessctl
    pamixer
    pavucontrol

    # gui 
    altair # graphql client
    insomnia # rest client
    polymc
    firefox
    firefox-devedition-bin
    google-chrome
    discord
    spotify

    unstable.earthly
    docker-compose

    # programming languages 
    gnumake
    go_1_17
    poetry
    nodejs
    yarn
    gcc
    tree-sitter
    ctags

    # lsps
    gopls
    goimports
    terraform-lsp
    pyright
    rust-analyzer
    stylua
    efm-langserver
    sumneko-lua-language-server
    pkgs.nodePackages.prettier
    nodePackages.eslint_d
    nodePackages.json-server
    nodePackages.diagnostic-languageserver
    nodePackages.vscode-css-languageserver-bin
    nodePackages.vscode-html-languageserver-bin
    nodePackages.dockerfile-language-server-nodejs
    nodePackages.bash-language-server
    nodePackages.typescript-language-server
    rnix-lsp
  ];
  virtualisation.docker.enable = true;
  virtualisation.docker.autoPrune.enable = true;

  security.pam.yubico = {
    enable = true;
    debug = false;
    mode = "challenge-response";
  };
  security.pam.yubico.control = "sufficient";

  programs.mtr.enable = true;
  programs.steam.enable = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  hardware.pulseaudio.support32Bit = true;
  hardware.steam-hardware.enable = true;
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    configure = {
      customRC = ''
        luafile /home/kschoon/.config/nvim/lua/init.lua
      '';
      packages.nix.start = with pkgs.vimPlugins; [
        nvim-treesitter
        nvim-treesitter-textobjects
        vim-fugitive
        vim-rhubarb
        vim-commentary
        vim-gutentags
        telescope-nvim
        onedark-vim
        lightline-vim
        indent-blankline-nvim
        gitsigns-nvim
        plenary-nvim

        nvim-lspconfig

        # completion
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        cmp-cmdline
        nvim-cmp
        cmp_luasnip
        luasnip
        lsp_signature-nvim
      ];
    };
  };
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
}

