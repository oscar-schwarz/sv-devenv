{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (builtins) readFile;
  inherit (lib) mkEnableOption mkIf;

  cfg = config.sv.vite-vue-laravel;
in {
  options.sv.vite-vue-laravel = {
    enable = mkEnableOption "development environment for a project using Vue for a JS frontend, Vite for bundling it and Laravel as a backend";
  };
  config = mkIf cfg.enable {
    git-hooks.hooks = {
      check-types-ts = {
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
    };
  };
}