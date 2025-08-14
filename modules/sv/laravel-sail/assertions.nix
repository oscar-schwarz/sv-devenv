{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (builtins) match elem;
  inherit (lib) mkIf;

  cfg = config.sv.laravel-sail;

  assertValidPort = name: {
    assertion = (match "^[0-9]{4,}$" config.envFile.${name}) != null;
    message =".env: ${name} (${config.envFile.${name}}) is either not a valid port or needs super user to be used. A valid port which can be accessed by normal users is a number between 1000 and 65535.";
  };

in mkIf cfg.enable {
  assertions = [
    (assertValidPort "APP_PORT")
    {
      assertion = config.envFile.APP_ENV == config.envFile.VITE_APP_ENV;
      message = ".env: APP_ENV (${config.envFile.APP_ENV}) and VITE_APP_ENV (${config.envFile.VITE_APP_ENV}) are not equal."; 
    }
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
      message =".env: DB_HOST (${config.envFile.DB_HOST}) contains invalid characters. This needs to be a container name such as 'mariadb'";
    }
    # {
      # assertion = (config.envFile.SAIL_XDEBUG_CONFIG == "client_host=10.0.2.2");
      # message = ".env: SAIL_XDEBUG_CONFIG (${config.envFile.SAIL_XDEBUG_CONFIG}) needs to be set to 'client_host=10.0.2.2' so that the laravel container can reach the host for debugging.";
    # }
  ];
}
