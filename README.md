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

### Passwordless sudo
[docs](https://nixos.wiki/wiki/Yubikey#yubico-pam)

## Resources

1. <https://nixos.wiki/wiki/Nixpkgs/Create_and_debug_packages>
2. <https://nixpk.gs/pr-tracker.html?pr=160499>
