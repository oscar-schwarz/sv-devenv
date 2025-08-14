{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (builtins) attrNames head typeOf;
  inherit (lib) pipe mkDefault mkIf filterAttrs;

  cfg = config.sv;
  # config.lib
  cfgLib = rec {
    enabledModule = pipe cfg [
      (filterAttrs (_: value: (typeOf value == "set") && (value ? "enable") && value.enable))
      attrNames
      (list: if list == [] then null else (head list))
    ];
    enable = enabledModule != null;
  };
in {
  options.sv = {};
  config = {
    # Some useful functions
    lib.sv = cfgLib;
    
    # Disable the cachix cache by default
    cachix.enable = mkDefault false;

    packages = with pkgs; [
      jq
      glow
    ];

    # Define available patches
    patches = {
      xdebug = {
        diffFile = ../../diff/xdebug-fix.diff;
        patchedFile = {
          localPath = "vendor/laravel/sail/runtimes/8.3/php.ini";
          isTracked = false;
        };
      };
      
      viteHmr = {
        diffFile = ../../diff/hmr-fix.diff;
        patchedFile = {
          localPath = "vite.config.js";
          isTracked = true;
        };
      };
    };

    # Define a welcome message when opening the shell
    enterShell = mkIf cfgLib.enable /*bash*/''
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
      | glow --width 0


      # --- Check for new version of the flake (only if found in lock)
      if [[ "$(cat devenv.lock | jq '.nodes."sv-devenv"')" != "null" ]]; then

        # --- Get repository information and current revision (commit hash) from lockfile
        export locked=$(cat devenv.lock | jq -r '.nodes."sv-devenv".locked')
        export owner=$(echo $locked | jq -r '.owner')
        export repo=$(echo $locked | jq -r '.repo')
        export currentRev=$(echo $locked | jq -r '.rev')

        # --- Get the possibly updated revision
        export updatedRev=$(curl -s "https://api.github.com/repos/$owner/$repo/branches" | jq -r 'if .message == null then .[] | select(.name == "main").commit.sha else "Not found" end')

        if [[ "$currentRev" != "Not found" ]] && [[ "$currentRev" != "$updatedRev" ]]; then
          echo -e '
        ## An update is available for this developer shell!

        Get the newest version with: `devenv update sv-devenv`
          '\
          | glow --width 0
        fi
      fi


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
    git-hooks.hooks = mkIf cfgLib.enable {
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
