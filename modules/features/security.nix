{ ... }:
{
  flake.nixosModules.security = { ... }:
  let
    # One passphrase entry covers a working day.
    gpgCacheTtlSeconds = 8 * 60 * 60;
  in
  {
    security.pam.yubico = {
      enable = true;
      debug = false;
      mode = "challenge-response";
      id = [ "14403606" "11584605" "15202067" ];
      control = "sufficient";
    };
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      # max-* caps the default-* TTLs (gpg-agent default 2h), so raise both.
      settings = {
        default-cache-ttl = gpgCacheTtlSeconds;
        max-cache-ttl = gpgCacheTtlSeconds;
        default-cache-ttl-ssh = gpgCacheTtlSeconds;
        max-cache-ttl-ssh = gpgCacheTtlSeconds;
      };
    };

    # Disable GNOME Keyring — using 1password + gnupg instead
    # Prevents unlock prompt with greetd autologin (no password to unlock with)
    services.gnome.gnome-keyring.enable = false;
    security.pam.services.greetd.enableGnomeKeyring = false;
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "kschoon" ];
    };
    programs.mtr.enable = true;
  };
}
