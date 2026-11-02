{
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;

  cfg = config.sv.app-wrapper;
in {
  config = mkIf (cfg.enable && cfg.flavor == "beste") {
    sv.app-wrapper.avd.name = "beste";
  };
}
