{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;

  cfg = config.sv.laravel-sail;
  cfgLib = config.lib;
in {
  config = mkIf (cfg.enable && cfg.flavor == "planer") {
    assertions = [
      (cfgLib.assertionValidPort "CADDY_PORT" config.envFile)
    ];
    
    sv.laravel-sail.nodejs-frontend = {
      enable = true;
      needsGithubSSH = true;
    };

    patches.useCaddyPortVariable.enable = true;
  };
}
