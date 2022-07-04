#!/usr/bin/env bash
# TODO: before running nix-shell https://github.com/sgillespie/nixos-yubikey-luks/archive/master.tar.gz

rbtohex() {
    ( od -An -vtx1 | tr -d ' \n' )
}

hextorb() {
    ( tr '[:lower:]' '[:upper:]' | sed -e 's/\([0-9A-F]\{2\}\)/\\\\\\x\1/gI'| xargs printf )
}

LUKS_PARTITION=/dev/nvme0n1p3 
CRYPT_STORAGE=/boot/crypt-storage/default
SALT_LENGTH=16
KEY_LENGTH=512
SALT=`head -n 1 $CRYPT_STORAGE`
CHALLENGE="$(echo -n $SALT | openssl dgst -binary -sha512 | rbtohex)"
ITERATIONS=`tail -n 1 $CRYPT_STORAGE`
CIPHER=aes-xts-plain64
HASH=sha512
RESPONSE=$(ykchalresp -2 -x $CHALLENGE 2>/dev/null)
LUKS_KEY="$(echo | pbkdf2-sha512 $(($KEY_LENGTH / 8)) $ITERATIONS $RESPONSE | rbtohex)"
echo $LUKS_KEY | hextorb > out.file
# echo -n "$LUKS_KEY" | hextorb | sudo cryptsetup luksAddKey --key-file=- $LUKS_PARTITION
# shred -n 5 -z -u -v out.file
