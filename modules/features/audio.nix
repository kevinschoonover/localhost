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
        # Prefix node.name with ~ for regex matching (e.g. "~bluez_output.XX_XX.*").
        # Bluetooth outputs spell the address with underscores, inputs with
        # colons; an unescaped `.` matches either.
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

        # WirePlumber restores the most recently *chosen* output, so after a
        # manual pick of the Samson or the monitor, newly connected headphones
        # never take over. Choosing every Bluetooth output as it appears makes
        # audio follow whichever pair was just connected; when it goes away,
        # WirePlumber falls back down its usual history.
        wireplumber.extraScripts."custom/bluetooth-default-sink.lua" = ''
          log = Log.open_topic ("s-custom-bluetooth-default-sink")

          SimpleEventHook {
            name = "custom/bluetooth-default-sink",
            interests = {
              EventInterest {
                Constraint { "event.type", "=", "node-added" },
                Constraint { "media.class", "=", "Audio/Sink" },
                Constraint { "node.name", "matches", "bluez_output.*" },
              },
            },
            execute = function (event)
              local name = event:get_subject ().properties ["node.name"]
              local om = event:get_source ():call ("get-object-manager", "metadata")
              local metadata = om:lookup { Constraint { "metadata.name", "=", "default" } }
              if metadata == nil then
                log:warning ("no default metadata; leaving output for " .. name)
                return
              end
              log:info ("bluetooth output added, choosing it: " .. name)
              metadata:set (0, "default.configured.audio.sink", "Spa:String:JSON",
                  Json.Object { ["name"] = name }:to_string ())
            end
          }:register ()
        '';
        wireplumber.extraConfig."90-bluetooth-default-sink" = {
          "wireplumber.components" = [
            {
              name = "custom/bluetooth-default-sink.lua";
              type = "script/lua";
              provides = "custom.bluetooth-default-sink";
            }
          ];
          "wireplumber.profiles".main."custom.bluetooth-default-sink" = "required";
        };
      };
      environment.systemPackages = with pkgs; [
        pamixer
        pavucontrol
      ];
    };
}
