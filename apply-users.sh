#!/bin/sh
pushd ~/nix-config
home-manager switch -f ./home-manager/home.nix
popd
