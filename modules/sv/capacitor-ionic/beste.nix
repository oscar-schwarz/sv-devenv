{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;

  cfg = config.sv.capacitor-ionic;
in {
  config = mkIf (cfg.enable && cfg.flavor == "beste") {
    # Flavor-specific configuration for beste will be added here
  };
}
