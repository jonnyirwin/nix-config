{ config, pkgs, lib, inputs, ... }:

# Shared NixOS config applied to every machine.
# Hardware, desktop, and host-specific options live elsewhere.
{
  # ── Nix ────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store   = true;
  };

  # Keep the system on nixpkgs-unstable (same as HM).
  nixpkgs.config.allowUnfree = true;

  # ── Locale / time ──────────────────────────────────────────
  time.timeZone              = "Europe/London";
  i18n.defaultLocale         = "en_GB.UTF-8";
  console.keyMap             = "uk";

  # ── Networking ─────────────────────────────────────────────
  networking.networkmanager.enable = true;

  # ── User ───────────────────────────────────────────────────
  users.users.jonny = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" "video" "audio" "input" ];
    shell        = pkgs.fish;
  };

  # Fish needs to be enabled at the system level so /etc/shells is populated,
  # which is required for it to be a valid login shell.
  programs.fish.enable = true;

  # ── Base system packages ────────────────────────────────────
  # Keep this minimal — user packages belong in Home Manager.
  environment.systemPackages = with pkgs; [
    git       # needed before HM is bootstrapped
    vim       # emergency editor without HM
    wget
    curl
  ];

  # ── SSH daemon ─────────────────────────────────────────────
  services.openssh = {
    enable                 = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin        = "no";
  };

  # ── Security ───────────────────────────────────────────────
  # Passwordless sudo for the wheel group (jonny is a member). Convenient on a
  # single-user machine; note it means any process running as your user can gain
  # root without a prompt, so keep it off on shared/untrusted systems.
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "24.11";
}
