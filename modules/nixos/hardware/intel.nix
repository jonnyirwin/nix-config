{ lib, config, pkgs, ... }:

let
  cfg = config.jonny.hardware.intel;
in
{
  options.jonny.hardware.intel.enable =
    lib.mkEnableOption "Intel CPU/GPU support (microcode, VA-API)";

  config = lib.mkIf cfg.enable {
    hardware = {
      cpu.intel.updateMicrocode = true;
      enableRedistributableFirmware = true;

      graphics.extraPackages = with pkgs; [
        intel-media-driver # VA-API on Broadwell and newer
        vpl-gpu-rt # QuickSync video encode/decode
      ];
    };
  };
}
