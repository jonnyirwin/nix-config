#!/bin/sh
pushd ~/nix-config
sudo nixos-rebuild switch -I nixos-config=./nixos/configuration.nix
popd
