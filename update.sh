#!/usr/bin/env bash
# TODO: don't seperate by hostname
hostname=`cat /etc/hostname`
mkdir -p $hostname-nixos/
ln -s $(pwd)/generic.nix /etc/nixos/
ln -s $(pwd)/flake.nix /etc/nixos/
ln -s $(pwd)/flake.lock /etc/nixos/
ln -s $(pwd)/$hostname-nixos/ /etc/nixos/
