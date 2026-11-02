{
  lib,
  config,
  self,
  options,
  ...
}: let
  inherit (builtins) pathExists readFile;
  inherit (lib) mkIf mkOption;
  inherit (config.lib) fromDotenv;

  cfgLib = config.lib.sv;
in {
  options = {
    envFile = mkOption {
      description = ''
        Devenv does not parse .env files correctly. We also need to substitute variables and remove comments. This is done here.
      '';
      type = options.env.type;
      default = {};
    };
  };

  config = mkIf cfgLib.enable {
    # We are rejecting the devenv dotenv integration because of the following reasons
    # 1. It is incomplete, it does not substitute variables such as VAR=$(OTHER)
    # 2. does not remove comments behind a declaration
    # 3. there is no easy way to parse the .env file without adding it to the environment.
    dotenv = {
      enable = false;
      disableHint = true;
      # newer devenv versions read this even when dotenv is disabled
      resolved = config.envFile;
    };
    envFile =
      if pathExists "${self}/.env"
      then fromDotenv (readFile "${self}/.env")
      else {};
  };
}
