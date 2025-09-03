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
    # Flavor-specific configuration for plan will be added here
  };
}
