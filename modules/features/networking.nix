{ ... }:
{
  flake.nixosModules.networking = { ... }: {
    networking.networkmanager.enable = true;
    networking.wireless.iwd.enable = true;
    networking.networkmanager.wifi.backend = "iwd";
    networking.nftables.enable = true;

    services.resolved.enable = true;
    services.resolved.dnssec = "false";
    services.resolved.fallbackDns = [
      "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001"
      "8.8.8.8" "8.8.4.4" "2001:4860:4860::8888" "2001:4860:4860::8844"
    ];
    networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];

    networking.firewall.interfaces.tailscale0.allowedUDPPorts = [ 3000 9876 9877 ];
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
      22 80 443 8372 3000 3001 8080 8081 9998 9999 15636 15637
    ];
    networking.firewall.interfaces.wlan0.allowedUDPPorts = [ 8081 19000 3000 3001 ];
    networking.firewall.interfaces.wlan0.allowedTCPPorts = [ 8081 9998 9999 19000 3000 3001 ];
    networking.firewall.interfaces.docker0.allowedTCPPorts = [ 8080 ];
  };
}
