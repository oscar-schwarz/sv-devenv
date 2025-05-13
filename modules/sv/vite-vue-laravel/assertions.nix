{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (builtins) match elem;
  inherit (lib) mkIf;

  cfg = config.sv.vite-vue-laravel;

  assertValidPort = name: {
    assertion = (match "^[0-9]{4,}$" config.env.${name}) != null;
    message =".env: ${name} (${config.env.${name}}) is either not a valid port or needs super user to be used.";
  };

  assertNoReferenceOther = name: {
    assertion = (match ".*[\{\}\$].*" config.dotenv.resolved.${name}) == null;
    message = ".env: ${name} (${config.dotenv.resolved.${name}}) contains invalid characters. Note that this variable cannot reference other variables.";
  };

in mkIf cfg.enable {
  assertions = [
    (assertValidPort "APP_PORT")
    (assertNoReferenceOther "APP_URL")
    {
      assertion = config.env.APP_ENV == config.env.VITE_APP_ENV;
      message = ".env: APP_ENV (${config.env.APP_ENV}) and VITE_APP_ENV (${config.env.VITE_APP_ENV}) are not equal."; 
    }
    {
      assertion = (match "^http://(localhost|127.0.0.1):[0-9].*" config.env.APP_URL) != null;
      message = ".env: APP_URL (${config.env.APP_URL}) is either not a valid URL, not a localhost URL or not on port that can be accessed without root."; 
    }
    {
      assertion = (match ".*:${config.env.APP_PORT}$" config.env.APP_URL) != null;
      message = ".env: APP_PORT (${config.env.APP_PORT}) must be the port of APP_URL (${config.env.APP_URL})";
    }
    {
      assertion = (match ".*[\{\}\$].*" config.dotenv.resolved.APP_URL) == null;
      message = ".env: APP_URL (${config.dotenv.resolved.APP_URL}) contains invalid characters. Note that this variable cannot reference other variables.";
    }
  ] ++ (if cfg.sail.enable then [
    (assertValidPort "FORWARD_DB_PORT")
    {
      assertion = (match ".*[/():.].*" config.env.DB_HOST) == null;
      message =".env: DB_HOST (${config.env.DB_HOST}) contains invalid characters. In sail mode, this needs to be a container name such as 'mariadb'";
    }
    {
      assertion = (!cfg.sail.dockerd.enable) || (!cfg.sail.enableXDebugPatch) || (match ".*dockerd-rootless.*" cfg.sail.dockerd.exec == null) || (config.env.SAIL_XDEBUG_CONFIG == "client_host=10.0.2.2");
      message = ".env: SAIL_XDEBUG_CONFIG (${config.env.SAIL_XDEBUG_CONFIG}) needs to be set to 'client_host=10.0.2.2' so that the laravel container can reach the host for debugging.";
    }
  ] else []);
}