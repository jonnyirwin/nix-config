{ pkgs, ... }:

{
  # Deliberately minimal — enough to repair a system with no Home Manager
  # profile activated. Everything else belongs in modules/home.
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
  ];
}
