{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (builtins) getAttr;
  inherit (lib) mkIf;

  env = config.subEnv;
  cfg = config.beste-schule;
  localLib = config.lib.beste-schule;

in mkIf cfg.enable {

  git-hooks.hooks = {
    check-added-large-files.enable = true;
    check-merge-conflicts.enable = true;
    shellcheck.enable = true;
    shfmt.enable = true;
    no-commit-to-branch = {
      enable = true;
      settings.branch = [ "main" "master" "production" ];
      always_run = true;
    };
    check-types-ts = mkIf localLib.isWeb {
      enable = true;
      name = "check-types-ts";
      description = "does some validation on types.ts, like type sorting order";
      files = "^resources/js/types\.ts$";
      entry = let
        pkg = pkgs.writeShellApplication {
          name = "check-types-ts";
          runtimeInputs = [pkgs.ripgrep pkgs.coreutils];
          text = ''
            rg '^export (type|interface) (\w+)' --only-matching --replace '$2' --no-filename "$${@}" | sort --check
          '';
        };
      in
        lib.getExe pkg;
    };
  };
}