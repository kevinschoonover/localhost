#!/usr/bin/env bash
# TODO: before running nix-shell https://github.com/sgillespie/nixos-yubikey-luks/archive/master.tar.gz -p git
rbtohex() {
    ( od -An -vtx1 | tr -d ' \n' )
}

hextorb() {
    ( tr '[:lower:]' '[:upper:]' | sed -e 's/\([0-9A-F]\{2\}\)/\\\\\\x\1/gI'| xargs printf )
}

DISK=/dev/nvme1n1
SALT_LENGTH=16
KEY_LENGTH=512
ITERATIONS=1000000
CIPHER=aes-xts-plain64
HASH=sha512
EFI_PARTITION=${DISK}p1
LUKS_PARTITION=${DISK}p2
sudo parted $DISK -- mklabel gpt
sudo parted $DISK -- mkpart ESP fat32 1MiB 512MiB
sudo parted $DISK -- set 1 esp on
sudo parted $DISK -- mkpart primary 512MiB 100%
ykpersonalize -2 -ochal-resp -ochal-hmac -oserial-api-visible
SALT="$(dd if=/dev/random bs=1 count=$SALT_LENGTH 2>/dev/null | rbtohex)"
CHALLENGE="$(echo -n $SALT | openssl dgst -binary -sha512 | rbtohex)"
RESPONSE=$(ykchalresp -2 -x $CHALLENGE 2>/dev/null)
LUKS_KEY="$(echo | pbkdf2-sha512 $(($KEY_LENGTH / 8)) $ITERATIONS $RESPONSE | rbtohex)"
echo -n "$LUKS_KEY" | hextorb | sudo cryptsetup luksFormat --cipher="$CIPHER" --key-size="$KEY_LENGTH" --hash="$HASH" --key-file=- $LUKS_PARTITION
sudo mkfs.fat -F32 -n boot $EFI_PARTITION
echo -n "$LUKS_KEY" | hextorb | sudo cryptsetup open $LUKS_PARTITION encrypted --key-file=-
sudo pvcreate /dev/mapper/encrypted 
sudo pvcreate /dev/mapper/encrypted 
sudo vgcreate vg1 /dev/mapper/encrypted
sudo lvcreate -L 8G vg1 -n swap
sudo lvcreate -l +100%FREE vg1 -n root
sudo lvdisplay
sudo mkfs.ext4 -L nixos /dev/mapper/vg1-root 
sudo mkswap -L swap /dev/mapper/vg1-swap 
sudo swapon /dev/mapper/vg1-swap 
sudo mount /dev/mapper/vg1-root /mnt/
sudo mkdir -p /mnt/boot
sudo mount $EFI_PARTITION /mnt/boot/
sudo mkdir -p /mnt/boot/crypt-storage
echo -ne "$SALT\n$ITERATIONS" | sudo tee -a /mnt/boot/crypt-storage/default
sudo nixos-generate-config --root /mnt/
