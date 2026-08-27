# localhost

> there is no place like home

Personal dotfiles / installation instructure for my personal setup using NixOS.

## Usage
### Flashing the ISO
1. download the [nixos iso](https://nixos.org/download)

2. flash the image
    ```bash
    sudo dd if=<input_file> of=<device_name> status=progress bs=4096 
    sync
    ```

### Machine setup
#### Formatting the drive

```bash
DRIVE=/dev/nvme0n1
parted $DRIVE -- mklabel gpt
parted $DRIVE -- mkpart ESP fat32 1MiB 512MiB
parted $DRIVE -- mkpart primary linux-swap 512MiB 8.5GiB
parted $DRIVE -- mkpart primary 8.5GiB 100%
parted $DRIVE -- set 1 boot on
mkfs.fat -F32 -n BOOT ${DRIVE}p1
mkswap -L swap ${DRIVE}p2
mkfs.ext4 -L nixos ${DRIVE}p3
```

#### Installing
```bash
DRIVE=/dev/nvme0n1
mount ${DRIVE}p3 /mnt
mkdir -p /mnt/boot
mount ${DRIVE}p1 /mnt/boot
swapon ${DRIVE}p2

sudo nixos-generate-config --root /mnt/
```

### Adding a new machine to the flake

Each machine is a host module under `modules/hosts/<name>/`. The flake auto-imports
every module via `import-tree`, so a new host directory is picked up without editing
`flake.nix`.

The example below uses `honeypot` as the template; substitute any existing host that
most closely matches the new machine's role.

1. **Clone the flake into `/mnt/etc/nixos`** after the install steps above. Putting
   it there makes the `update` alias and bare `nixos-rebuild switch` resolve the
   flake automatically:

    ```bash
    nix-shell -p git
    sudo git clone https://github.com/kevinschoonover/localhost.git /mnt/etc/nixos
    cd /mnt/etc/nixos
    ```

2. **Copy a template host directory:**

    ```bash
    HOST=<new-hostname>
    sudo cp -r modules/hosts/honeypot modules/hosts/$HOST
    ```

3. **Regenerate hardware config** for the target machine:

    ```bash
    sudo nixos-generate-config --show-hardware-config \
      | sudo tee modules/hosts/$HOST/hardware-configuration.nix.raw >/dev/null
    ```

    Then merge `hardware-configuration.nix.raw` into
    `modules/hosts/$HOST/hardware-configuration.nix`, preserving the
    `flake.nixosModules.<host>Hardware` wrapper.

4. **Rename module identifiers** in the new host directory so they no longer
   collide with the template:

    - `configuration.nix`:
      `flake.nixosModules.honeypotConfiguration` → `flake.nixosModules.<host>Configuration`,
      `self.nixosModules.honeypotHardware` → `self.nixosModules.<host>Hardware`,
      `networking.hostName = "<host>";`.
    - `default.nix`:
      `flake.nixosConfigurations.honeypot` → `flake.nixosConfigurations.<host>`,
      `self.nixosModules.honeypotConfiguration` → `self.nixosModules.<host>Configuration`.
    - `hardware-configuration.nix`:
      `flake.nixosModules.honeypotHardware` → `flake.nixosModules.<host>Hardware`.

5. **Adjust feature imports** in `configuration.nix` for the machine role (drop
   `gaming`, `niri`, etc. on a server). For non-Dell hardware, swap
   `inputs.nixos-hardware.nixosModules.dell-xps-13-9380` for the matching
   [nixos-hardware](https://github.com/NixOS/nixos-hardware) profile, or remove
   the import.

6. **Install** from the live ISO:

    ```bash
    sudo nixos-install --flake /mnt/etc/nixos#$HOST
    reboot
    ```

    On an already-running NixOS machine, use `nixos-rebuild` instead:

    ```bash
    sudo nixos-rebuild switch --flake /etc/nixos#$HOST
    ```

7. **Commit the new host** so future rebuilds pick it up:

    ```bash
    cd /etc/nixos
    sudo git add modules/hosts/$HOST
    sudo git commit -m "feat(hosts): add $HOST"
    ```

### Updating

The `update` alias (defined in `modules/features/shell.nix`) bumps `flake.lock`
and switches the running system in one step:

```bash
update    # = pushd /etc/nixos && nix flake update; popd && sudo nixos-rebuild switch
```

Manual equivalents:

```bash
nix flake update                                    # bump all inputs
nix flake update nixpkgs                            # bump one input
sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)
sudo nixos-rebuild switch --rollback                # revert to previous gen
sudo nix-collect-garbage -d                         # GC old generations
```

### YubiKey LUKS (mothership)

`mothership` unlocks `/dev/nvme1n1p2` with the
[sgillespie yubikey-luks](https://github.com/sgillespie/nixos-yubikey-luks) scheme:
an HMAC-SHA1 challenge-response against YubiKey slot 2, with the salt and challenge
stored on the unencrypted `/dev/nvme1n1p1`. `setup.sh`, `addKey.sh` and
`generate-key.sh` in the repo root drive that setup.

This only works under **scripted stage 1**. nixpkgs 26.05 flipped
`boot.initrd.systemd.enable` to default `true`, so `modules/hosts/mothership/configuration.nix`
pins it back to `false`. Scripted stage 1 is **removed in 26.11**, and
`systemd-cryptenroll` speaks FIDO2/PKCS#11/TPM2 rather than challenge-response, so
there is no config-only translation — the LUKS header has to be re-enrolled.

#### Migrating to FIDO2 before 26.11

Needs physical access to mothership and a YubiKey 5 (4/NEO have no FIDO2
hmac-secret; those migrate via PIV/PKCS#11 instead).

1. **Confirm a passphrase keyslot exists first.** It is the only fallback if
   enrollment fails, and the machine will not boot without one.

    ```bash
    sudo cryptsetup luksDump /dev/nvme1n1p2
    ```

2. **Enroll the FIDO2 credential:**

    ```bash
    sudo systemd-cryptenroll --fido2-device=auto /dev/nvme1n1p2
    ```

3. **Swap the host config** in `modules/hosts/mothership/configuration.nix`:

    ```nix
    boot.initrd.systemd.enable = true;
    boot.initrd.luks.devices."encrypted" = {
      device = "/dev/nvme1n1p2";
      crypttabExtraOpts = [ "fido2-device=auto" ];
    };
    ```

    Drop `boot.initrd.luks.yubikeySupport`, the `yubikey = { ... }` block, and the
    `vfat`/`nls_*` initrd modules that only existed to read the salt partition.

4. **Rebuild and reboot.** Verify the FIDO2 unlock works before going further.

5. **Only then retire the old slot.** A stale challenge-response slot interferes
   with passphrase fallback:

    ```bash
    sudo systemd-cryptenroll --wipe-slot=<old-slot> /dev/nvme1n1p2
    ```

    `/dev/nvme1n1p1` (salt/challenge storage) is dead once that slot is gone.

### Passwordless sudo
[docs](https://nixos.wiki/wiki/Yubikey#yubico-pam)

## Resources

1. <https://nixos.wiki/wiki/Nixpkgs/Create_and_debug_packages>
2. <https://nixpk.gs/pr-tracker.html?pr=160499>
