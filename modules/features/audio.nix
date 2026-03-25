{ ... }:
{
  flake.nixosModules.audio =
    { pkgs, ... }:
    {
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        wireplumber.enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        # To find node.name values for new devices, connect the device then run:
        #   pw-dump | jq -r '.[] | select(.type == "PipeWire:Interface:Node") | select(.info.props["media.class"] // "" | test("Audio")) | "\(.info.props["node.name"]) | \(.info.props["node.description"])"'
        # Use monitor.alsa.rules for USB/built-in, monitor.bluez.rules for bluetooth.
        # Prefix node.name with ~ for glob matching (e.g. "~bluez_output.XX_XX.*").
        wireplumber.extraConfig."51-rename-devices" = {
          "monitor.alsa.rules" = [
            {
              matches = [ { "node.name" = "alsa_output.pci-0000_c1_00.6.analog-stereo"; } ];
              actions.update-props = {
                "node.description" = "Laptop Speakers";
                "node.nick" = "Laptop Speakers";
              };
            }
            {
              matches = [ { "node.name" = "alsa_input.pci-0000_c1_00.6.analog-stereo"; } ];
              actions.update-props = {
                "node.description" = "Laptop Mic";
                "node.nick" = "Laptop Mic";
              };
            }
            {
              matches = [
                {
                  "node.name" = "alsa_output.usb-C-Media_Electronics_Inc._USB_Advanced_Audio_Device-00.analog-stereo";
                }
              ];
              actions.update-props = {
                "node.description" = "Samson Q2U";
                "node.nick" = "Samson Q2U";
              };
            }
            {
              matches = [
                {
                  "node.name" = "alsa_input.usb-C-Media_Electronics_Inc._USB_Advanced_Audio_Device-00.analog-stereo";
                }
              ];
              actions.update-props = {
                "node.description" = "Samson Q2U";
                "node.nick" = "Samson Q2U";
              };
            }
          ];
          "monitor.bluez.rules" = [
            {
              matches = [ { "node.name" = "~bluez_output.F8_4E_17_16_B2_34.*"; } ];
              actions.update-props = {
                "node.description" = "Sony WH-1000XM4";
                "node.nick" = "Sony XM4";
              };
            }
            {
              matches = [ { "node.name" = "~bluez_input.F8.4E.17.16.B2.34.*"; } ];
              actions.update-props = {
                "node.description" = "Sony WH-1000XM4 Mic";
                "node.nick" = "Sony XM4 Mic";
              };
            }
          ];
        };
      };
      environment.systemPackages = with pkgs; [
        pamixer
        pavucontrol
      ];
    };
}
