#!/usr/bin/env bash
# TODO: don't seperate by hostname
hostname=`cat /etc/hostname`
mkdir -p $hostname-nixos/
ln -s $(pwd)/generic.nix /etc/nixos/
ln -s $(pwd)/$hostname-nixos/hardware-configuration.nix /etc/nixos/
ln -s $(pwd)/$hostname-nixos/configuration.nix /etc/nixos/

git add .
git commit
