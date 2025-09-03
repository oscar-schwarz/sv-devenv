{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (builtins) match elem;
  inherit (lib) mkIf;

  cfg = config.sv.laravel-sail;

  cfgLib = config.lib;
in
  mkIf cfg.enable {
    assertions = [
      (cfgLib.assertionValidPort "APP_PORT" config.envFile)
      {
        assertion = (match "^http://(localhost|127.0.0.1):[0-9].*" config.envFile.APP_URL) != null;
        message = ".env: APP_URL (${config.envFile.APP_URL}) is either not a valid URL, not a localhost URL or not on port that can be accessed without root.";
      }
      {
        assertion = (match ".*:${config.envFile.APP_PORT}$" config.envFile.APP_URL) != null;
        message = ".env: APP_PORT (${config.envFile.APP_PORT}) must be the port of APP_URL (${config.envFile.APP_URL})";
      }
      {
        assertion = (match ".*[/():.].*" config.envFile.DB_HOST) == null;
        message = ".env: DB_HOST (${config.envFile.DB_HOST}) contains invalid characters. This needs to be a container name such as 'mariadb'";
      }
    ];
  }
