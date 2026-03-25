{ ... }:
{
  flake.nixosModules.certificates = { ... }:
  let
    internalCA = builtins.readFile (
      builtins.fetchurl {
        url = "https://vault.prod.stratos.host:8200/v1/internal/ca/pem";
        sha256 = "d69f2f83b9999d1462a5d25dba4cfafbfaf8569894d4d08f81d2f9878e1237a2";
      }
    );
  in
  {
    security.pki.certificates = [ internalCA ];
  };
}
