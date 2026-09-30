{ inputs, ... }:
let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
in
{
  # Noctalia v5 reads every *.toml in $NOCTALIA_CONFIG_HOME/noctalia/, sorted
  # by name and merged. The shared base config ships as 00-base.toml and each
  # host's `localhost.noctalia.settings` lands on top as 50-host.toml. GUI edits
  # never touch either: they go to ~/.local/state/noctalia/settings.toml.
  flake.nixosModules.noctalia =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.localhost.noctalia;
      tomlFormat = pkgs.formats.toml { };
      noctalia = pkgs-unstable.noctalia;

      hostSettings = tomlFormat.generate "noctalia-host.toml" cfg.settings;

      configHome =
        pkgs.runCommand "noctalia-config-home"
          {
            nativeBuildInputs = [ noctalia ];
          }
          ''
            install -Dm444 ${./noctalia.toml} $out/noctalia/00-base.toml
            install -Dm444 ${hostSettings} $out/noctalia/50-host.toml

            # `validate` exits 0 on unknown keys and bad enum values (warnings).
            # A typo would then ship silently, so any warning fails the build.
            noctalia config validate $out/noctalia | tee validate.log
            if grep -q '^WARN' validate.log; then
              echo "noctalia config has warnings; refusing to build" >&2
              exit 1
            fi
          '';

      configured = pkgs.symlinkJoin {
        name = "noctalia-configured-${noctalia.version}";
        paths = [ noctalia ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/noctalia --set NOCTALIA_CONFIG_HOME ${configHome}
        '';
        passthru = {
          inherit configHome;
          inherit (noctalia) version;
        };
        meta = noctalia.meta // {
          mainProgram = "noctalia";
        };
      };
    in
    {
      options.localhost.noctalia = {
        settings = lib.mkOption {
          type = tomlFormat.type;
          default = { };
          example = lib.literalExpression ''
            {
              idle.behavior.suspend.enabled = false;
            }
          '';
          description = ''
            Host-specific noctalia settings, merged on top of noctalia.toml.
            Same TOML schema as https://docs.noctalia.dev/noctalia/configuration/.
          '';
        };

        package = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          default = configured;
          description = "noctalia wrapped with this host's generated config directory.";
        };
      };

      config = {
        environment.systemPackages = [ cfg.package ];

        # noctalia's control center and widgets talk to UPower and BlueZ. The
        # network widget needs no switch: noctalia falls back from NetworkManager
        # to wpa_supplicant to iwd, which these hosts run (networking.nix).
        services.upower.enable = true;
        hardware.bluetooth.enable = true;
      };
    };
}
