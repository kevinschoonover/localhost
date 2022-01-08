# localhost
> there is no place like home

Personal dotfiles / installation instructure for my personal setup using NixOS.

## Pre-Install Commands
```bash
ykpersonalize -2 -ochal-resp -ochal-hmac
sudo parted -s /dev/nvme0n1 mklabel gpt
sudo parted -s /dev/sda mkpart primary 2048s 2MiB
sudo parted -s /dev/nvme0n1 mkpart primary 2048s 2MiB
sudo parted -s /dev/nvme0n1 set 1 bios_grub on
sudo parted -s /dev/nvme0n1 mkpart primary fat32 2MiB 515MiB
sudo parted -s /dev/nvme0n1 set 2 boot on
sudo parted -s /dev/nvme0n1 set 2 esp on
sudo parted -s /dev/nvme0n1 mkpart primary 540MiB 100%
SALT_LENGTH=16
SALT="$(dd if=/dev/random bs=1 count=$SALT_LENGTH 2>/dev/null | rbtohex)"
CHALLENGE="$(echo -n $SALT | openssl dgst -binary -sha512 | rbtohex)"
RESPONSE=$(ykchalresp -2 -x $CHALLENGE 2>/dev/null)
KEY_LENGTH=512
ITERATIONS=1000000
LUKS_KEY="$(echo | pbkdf2-sha512 $(($KEY_LENGTH / 8)) $ITERATIONS $RESPONSE | rbtohex)"
CIPHER=aes-xts-plain64
HASH=sha512
echo -n "$LUKS_KEY" | hextorb | sudo cryptsetup luksFormat --cipher="$CIPHER" --key-size="$KEY_LENGTH" --hash="$HASH" --key-file=- /dev/nvme0n1p3
mkfs.fat -F32 /dev/nvme0n1p2
sudo mkfs.fat -F32 /dev/nvme0n1p2
sudo mkdir -p /mnt/boot/
sudo mount /dev/nvme0n1p2 /mnt/boot/
sudo echo -ne "$SALT\n$ITERATIONS" > /mnt/boot/crypt-storage/default
echo -n "$LUKS_KEY" | hextorb | sudo cryptsetup open /dev/nvme0n1p3 encrypted --key-file=-
pvcreate /dev/mapper/encrypted 
sudo pvcreate /dev/mapper/encrypted 
sudo vgcreate vg1 /dev/mapper/encrypted
sudo lvcreate -L 8G vg1 -n swap
sudo lvcreate -l +100%FREE vg1 -n root
sudo lvdisplay
sudo mkfs.ext4 -L nixos /dev/mapper/vg1-root 
sudo mkswap -L swap /dev/mapper/vg1-swap 
sudo mount /dev/mapper/vg1-root /mnt/
sudo mkdir -p /mnt/boot
sudo mount /dev/nvme0n1p2 /mnt/boot/
sudo swapon /dev/mapper/vg1-swap 
sudo mount /dev/mapper/vg1-root /mnt/
sudo mount /dev/nvme0n1p2 /mnt/boot/
sudo nixos-generate-config --root /mnt/
```

## Post Install
1. [register yubikey for login](https://nixos.wiki/wiki/Yubikey#Logging-in)
2. symlink dotfiles
