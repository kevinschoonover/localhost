#!/usr/bin/env bash
# TODO: don't seperate by hostname
hostname=`cat /etc/hostname`
mkdir -p $hostname-nixos/
sudo cp /etc/nixos/generic.nix .
sudo cp -r /etc/nixos/configuration.nix /etc/nixos/hardware-configuration.nix $hostname-nixos/
git add .
git commit
