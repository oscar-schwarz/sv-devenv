{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;

  cfg = config.sv.capacitor-ionic;
in {
  config = mkIf (cfg.enable && cfg.flavor == "plan") {
    packages = with pkgs; [
      yarn
    ];
  };
}
