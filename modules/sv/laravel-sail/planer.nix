{
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;

  cfg = config.sv.laravel-sail;
in {
  config = mkIf (cfg.enable && cfg.flavor == "planer") {
    sv.laravel-sail.nodejs-frontend.enable = true;
  };
}
