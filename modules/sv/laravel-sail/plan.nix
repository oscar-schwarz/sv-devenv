{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;

  cfg = config.sv.laravel-sail;
in {
  config = mkIf (cfg.enable && cfg.flavor == "plan") {
    # Enable Node.js frontend support
    sv.laravel-sail.nodejs-frontend.enable = true;

    patches.xdebug.enable = true;
  };
}
