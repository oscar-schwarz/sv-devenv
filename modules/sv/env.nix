{
  lib,
  config,
  self,
  options,
  ...
}: let
  inherit (builtins) attrNames elem filter pathExists readFile;
  inherit (lib) mkIf pipe mkOption attrsToList types concatLines;
  inherit (config.lib) fromDotenv;

  cfgLib = config.lib.sv;
in {
  options = {
    dotenv = {
      defaults = mkOption {
        description = ''
          The default values for certain values that are not found in the .env file.
        '';
        type = with types; attrsOf str;
        default = {};
      };
    };

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
      resolved =
        if pathExists "${self}/.env"
        then fromDotenv (readFile "${self}/.env")
        else {};
    };
    envFile = config.dotenv.defaults // config.dotenv.resolved;

    enterShell =
      ""
      # insert varaibles into .env which have defaults defined
      + (pipe config.dotenv.defaults) [
        attrsToList
        (filter (e: !(elem e.name (attrNames config.dotenv.resolved)))) # filter by not in env
        # map to commands
        (map (e: ''
          echo -e '\n${e.name}=${e.value}\n' >> .env
          echo "${e.name} not found in .env file. Adding it with a default value. (${e.value})"
        ''))
        # concat
        concatLines
      ];
  };
}
