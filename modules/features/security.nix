{ ... }:
{
  flake.nixosModules.security = { ... }: {
    security.pam.yubico = {
      enable = true;
      debug = false;
      mode = "challenge-response";
      id = [ "14403606" "11584605" "15202067" ];
      control = "sufficient";
    };
    programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "kschoon" ];
    };
    programs.mtr.enable = true;
  };
}
