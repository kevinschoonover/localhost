# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nixpkgs.config.allowUnfree = true;
  nix.autoOptimiseStore = true;
  environment.variables.EDITOR = "nvim";
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    XDG_CURRENT_DESKTOP = "sway";# https://github.com/emersion/xdg-desktop-portal-wlr/issues/20
    XDG_SESSION_TYPE = "wayland";# https://github.com/emersion/xdg-desktop-portal-wlr/pull/11
  };


  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "honeypot"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  # Set your time zone.
  time.timeZone = "America/Vancouver";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp57s0u1u3.useDHCP = true;
  networking.interfaces.wlan0.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  #
  fonts = {
    fonts = with pkgs; [
      nerdfonts
    ];
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Enable sound.
  # sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;  	
    alsa.enable = true;
    pulse.enable = true;
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
    extraGroups = [ "wheel" "video" "networkmanager" "docker"]; 
  };

  environment.interactiveShellInit = ''
   alias grep="ripgrep"
   alias cat="bat"
   alias ls="exa"

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
    #cli 
    vim tmux
    wget htop
    git gh
    ripgrep exa bat

    # passwords
    bitwarden bitwarden-cli
 
    # system-utils
    libnotify brightnessctl pamixer

    # gui 
    firefox firefox-devedition-bin discord

    unstable.earthly

    # programming languages 
    go poetry nodejs gcc tree-sitter
    ctags

    # lsps
    gopls terraform-lsp pyright 
    rust-analyzer
    stylua efm-langserver
    pkgs.nodePackages.prettier
    nodePackages.json-server
    nodePackages.diagnostic-languageserver
    nodePackages.diagnostic-languageserver
    rnix-lsp
  ];
  virtualisation.docker.enable = true;

  security.pam.yubico = {
    enable = true;
    debug = false;
    mode = "challenge-response";
  };
  security.pam.yubico.control = "sufficient";

  programs.mtr.enable = true;
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
	nvim-cmp
	cmp-nvim-lsp
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
    ];
  };

  services.tailscale.enable = true; 

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}

