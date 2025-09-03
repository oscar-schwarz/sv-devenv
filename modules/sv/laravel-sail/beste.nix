{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;

  cfg = config.sv.laravel-sail;
in {
  config = mkIf (cfg.enable && cfg.flavor == "beste") {
    # Enable Node.js frontend support
    sv.laravel-sail.nodejs-frontend = {
      enable = true;
      needsGithubSSH = true;
    };

    # Enable viteHmr patch
    patches.viteHmr.enable = true;
    patches.xdebug.enable = true;
    patches.checkJs.enable = true;

    # Enable check-types-ts git hook
    git-hooks.hooks.check-types-ts = {
      enable = true;
      name = "check-types-ts";
      description = "does some validation on types.ts, like type sorting order";
      files = "^resources/js/types\.ts$";
      entry = lib.getExe (pkgs.writeShellApplication {
        name = "check-types-ts";
        runtimeInputs = [pkgs.ripgrep pkgs.coreutils];
        text = ''
          rg '^export (type|interface) (\w+)' --only-matching --replace '$2' --no-filename "$@" | sort --check
        '';
      });
    };

    # VITE_APP_ENV assertion
    assertions = [
      {
        assertion = config.envFile.APP_ENV == config.envFile.VITE_APP_ENV;
        message = ".env: APP_ENV (${config.envFile.APP_ENV}) and VITE_APP_ENV (${config.envFile.VITE_APP_ENV}) are not equal.";
      }
    ];
  };
}
