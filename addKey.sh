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
LUKS_PARTITION=${DISK}p2
SALT="$(dd if=/dev/random bs=1 count=$SALT_LENGTH 2>/dev/null | rbtohex)"
CHALLENGE="$(echo -n $SALT | openssl dgst -binary -sha512 | rbtohex)"
RESPONSE=$(ykchalresp -2 -x $CHALLENGE 2>/dev/null)
LUKS_KEY="$(echo | pbkdf2-sha512 $(($KEY_LENGTH / 8)) $ITERATIONS $RESPONSE | rbtohex)"
echo -n "$LUKS_KEY" | hextorb > key.txt 
sudo cryptsetup luksAddKey $LUKS_PARTITION key.txt
echo -n "$LUKS_KEY" | hextorb | sudo cryptsetup open --test-passphrase $LUKS_PARTITION encrypted --key-file=-
echo -ne "$SALT\n$ITERATIONS" | sudo tee /boot/crypt-storage/default
