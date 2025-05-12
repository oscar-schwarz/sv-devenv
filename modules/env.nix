{ pkgs, lib, config, ... }: let 
  inherit (builtins) filter match hasAttr concatStringsSep replaceStrings listToAttrs getAttr;
  inherit (lib) mkIf pipe mkOption attrsToList;

  cfg = config.beste-schule;
  env = config.subEnv;
  localLib = config.lib.beste-schule;

  envVariablesPerRepo = import ../lib/variables.nix;

  # Assertions and warnings
  assertionsAndWarningsPerRepo = {
    web = [
      {
        type = "warning";
        assertion = env.APP_ENV == env.VITE_APP_ENV;
        message = "APP_ENV (${env.APP_ENV}) and VITE_APP_ENV (${env.VITE_APP_ENV}) are not equal."; 
      }
      {
        type = "warning";
        assertion = (match "^https?://(localhost|127.0.0.1):[0-9]{4,}.*" env.APP_URL) != null;
        message = "APP_URL (${env.APP_URL}) is either not a valid URL, not a localhost URL or not on port that can be accessed without root."; 
      }
    ];
    app = [

    ];
  };

in {
  options = {
    subEnv = mkOption {
      description = ''
        The same as `config.env` but with substituted values. 
        In .env files it is allowed to reference other variables with ''${VARIABLE}. Devenv does not parse that. So it is parsed here.
      '';
    };
  };

  config = mkIf cfg.enable {
    dotenv.enable = true;

    # Substitute env variables
    subEnv = pipe config.env [
      # a list of {name: ...; value: ...;} is easier to work with
      attrsToList

      # Now we need to substitute any variables (in dotenv you can reference another variable with ${VAR})
      (list: map ({name, value}: {
        inherit name;
        value = replaceStrings
          (map (e: "\${${e.name}}") list)
          (map (e: e.value) list)
          value;
      }) list)

      # to set again
      listToAttrs
    ];

    # We need to unset the variables as the env variables being defined in the shell breaks some things 
    enterShell = pipe envVariablesPerRepo.${cfg.repo}.all [
      # add command to unset env var
      (map (e: "unset ${e}"))

      # concat to string
      (concatStringsSep "\n")
    ];

    # Test the provided .env that no bullshit was provided
    warnings = pipe assertionsAndWarningsPerRepo.${cfg.repo} [
      # get warnings which have failed assertions
      (filter (e: e.type == "warning" && !e.assertion))
      # map to string array
      (map (e: ".env: " + e.message))
    ];

    assertions = (pipe assertionsAndWarningsPerRepo.${cfg.repo} [
      # filter assertions
      (filter (e: e.type == "assertion"))
      # omit type attribute
      (map (e: {inherit (e) assertion message;}))
    ]) 
    # Add assertion for required env variable
    ++ (map (name: {assertion = hasAttr name env; message = "${name} is not defined in the .env file.";}) (
      if (envVariablesPerRepo.${cfg.repo} ? required) then 
        envVariablesPerRepo.${cfg.repo}.required
      else
        envVariablesPerRepo.${cfg.repo}.all 
    ));
  };
}