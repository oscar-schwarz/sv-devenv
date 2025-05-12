{ pkgs, lib, config, ... }: let 
  inherit (builtins) filter match hasAttr concatStringsSep;
  inherit (lib) mkIf pipe;

  cfg = config.beste-schule;

  localLib = config.lib.beste-schule;

  envVariableNames = import ../lib/variable-names.nix;

in mkIf cfg.enable {
  dotenv.enable = true;

  # We need to unset the variables in the shell as the env variables being defined in the shell breaks some things 
  enterShell = pipe envVariableNames.${cfg.repo} [
    # add command to unset env var
    (map (e: "unset ${e}"))

    # concat to string
    (concatStringsSep "\n")
  ];

  # Test the provided .env that no bullshit was provided
  warnings = map (e: ".env: " + e.message) (filter (e: !e.assertion) ([]
   ++ (if localLib.isWeb then [
      {
        assertion = config.env.APP_ENV == config.env.VITE_APP_ENV;
        message = "APP_ENV (${config.env.APP_ENV}) and VITE_APP_ENV (${config.env.VITE_APP_ENV}) are not equal."; 
      }
      {
        assertion = match "^https?://localhost:\\d{4,}.*" config.env.APP_URL;
        message = "APP_URL (${config.env.APP_URL}) is either not a valid URL, not a localhost URL or not on port that can be accessed without root."; 
      }
    ] else [])
  ));

  assertions = [

  ] 
  ++ (map (name: {assertion = hasAttr name config.env; message = "${name} is not defined in the .env file.";}) 
    [ "APP_ENV" "VITE_APP_ENV" "APP_URL" ]
  );
}