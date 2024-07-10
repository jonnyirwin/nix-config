{ config, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos"; 
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Isle_of_Man";
  i18n.defaultLocale = "en_GB.UTF-8";
  console.keyMap = "uk";

  programs.sway.enable = true;
	programs.fish.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
	  enable = true;
	  alsa.enable = true;
	  alsa.support32Bit = true;
	  pulse.enable = true;
  };

  users.users.jonny = {
    isNormalUser = true;
    description = "Jonny";
    extraGroups = [ "networkmanager" "wheel" ];
    initialPassword = "Password123*";
		shell = pkgs.fish;
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim 
    wget
    git
    curl
    #helix.packages."${pkgs.system}".helix
    kitty
		tmux
		grim
		slurp
		wl-clipboard
  ];

   programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
   };


  #programs.nixvim = {
  #  enable = true; 
  #  colorschemes.tokyonight.enable = true;
  #  plugins.lualine.enable = true;
  #};

  services.openssh.enable = true;
  system.stateVersion = "23.05"; 
}
