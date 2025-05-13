{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (builtins) attrNames length concatStringsSep head;
  inherit (lib) pipe mkDefault mkEnableOption mkIf filterAttrs;

  cfg = config.sv;
  # config.lib
  cfgLib = rec {
    enabledModule = pipe cfg [
      (filterAttrs (_: value: value.enable))
      attrNames
      (list: if list == [] then null else (head list))
    ];
    enable = enabledModule != null;
  };
in {
  options.sv = {};
  config = mkIf cfgLib.enable {
    # Some useful functions
    lib.sv = cfgLib;
    
    # Disable the cachix cache by default
    cachix.enable = mkDefault false;

    # Define a welcome message when opening the shell
    enterShell = ''
      # --- Show available scripts and a welcome message
      echo -e '
      # SV Developer Shell

      **Environment** `${cfgLib.enabledModule}`

      **Available commands:**
      - `devenv up` - starts all necessary services
      ${lib.pipe config.scripts [
        # Only show scripts with a description
        (lib.attrsets.filterAttrs (_: script: script.description != ""))

        # Format the filtered set to a string showing name and description
        (lib.foldlAttrs (acc: name: value:
          acc
          + ''
            - `${name}` - ${config.scripts.${name}.description}
          '') "")
      ]}
      '\
      | ${lib.getExe pkgs.glow} --width 0

      # --- Making sure that devenv files are excluded from git history
      excludeGit=".git/info/exclude"
      files=".devenv devenv.nix devenv.local.nix devenv.yaml devenv.lock .devenv.flake.nix"
      for file in $files; do
        if ! grep -q "$file" "$excludeGit"; then
          echo Adding "$file" to "$excludeGit"
          echo "$file" >> "$excludeGit"
        fi
      done
    '';

    # Git hooks needed in any module
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
    };
  };
}
