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

### Passwordless sudo
[docs](https://nixos.wiki/wiki/Yubikey#yubico-pam)

## Resources

1. <https://nixos.wiki/wiki/Nixpkgs/Create_and_debug_packages>
2. <https://nixpk.gs/pr-tracker.html?pr=160499>
