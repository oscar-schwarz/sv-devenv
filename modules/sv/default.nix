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
      (list:
        if list == []
        then null
        else (head list))
    ];
    enable = enabledModule != null;
  };
in {
  options.sv = {
    extraWelcomeText = lib.mkOption {
      type = lib.types.lines;
      description = "Markdown formatted text added below \"Tech Stack\" and above \"Available Commands\" in the enterShell message.";
      default = "";
    };
    gitExclude = lib.mkOption {
      type = with lib.types; listOf str;
      description = "Files added to .git/info/exclude, because they are generated or only used locally.";
      default = [];
    };
  };
  config = {
    # Some useful functions
    lib.sv = cfgLib;

    cachix.enable = mkDefault true;

    packages = with pkgs; [
      jq
      glow
    ];

    # Define a welcome message when opening the shell
    enterShell =
      mkIf cfgLib.enable
      /*
      bash
      */
      ''
        # --- Show available scripts and a welcome message
        echo -e '

        # SV Developer Shell

        **Tech Stack:** `${cfgLib.enabledModule}`

        ${cfg.extraWelcomeText}

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


        # --- Check for new version of the flake (only if locked to GitHub, not to a local path)
        if [[ "$(jq -r '.nodes."sv-devenv".locked.type' devenv.lock 2>/dev/null)" == "github" ]]; then

          # --- Get repository information and current revision (commit hash) from lockfile
          svOwner=$(jq -r '.nodes."sv-devenv".locked.owner' devenv.lock)
          svRepo=$(jq -r '.nodes."sv-devenv".locked.repo' devenv.lock)
          svRef=$(jq -r '.nodes."sv-devenv".original.ref // "main"' devenv.lock)
          svCurrentRev=$(jq -r '.nodes."sv-devenv".locked.rev' devenv.lock)

          # --- Get the newest revision of the followed branch, empty when offline
          svUpdatedRev=$(GIT_TERMINAL_PROMPT=0 timeout 5 ${pkgs.git}/bin/git ls-remote "https://github.com/$svOwner/$svRepo" "refs/heads/$svRef" 2>/dev/null | cut -f1)

          if [[ -n "$svUpdatedRev" ]] && [[ "$svCurrentRev" != "$svUpdatedRev" ]]; then
            echo -e '
          ## An update is available for this developer shell!

          Get the newest version with: `devenv update sv-devenv`
            '\
            | glow --width 0
          fi
        fi


        # --- Making sure that devenv files are excluded from git history
        excludeGit=".git/info/exclude"
        files="${lib.concatStringsSep " " cfg.gitExclude}"
        for file in $files; do
          if ! grep -qxF "$file" "$excludeGit"; then
            echo Adding "$file" to "$excludeGit"
            echo "$file" >> "$excludeGit"
          fi
        done
      '';

    sv.gitExclude = [".devenv" "devenv.nix" "devenv.local.nix" "devenv.yaml" "devenv.lock" ".devenv.flake.nix" ".envrc" ".pre-commit-config.yaml"];

    # Git hooks needed in any module
    env.PREK_ALLOW_NO_CONFIG = 1; # to fix worktree creation
    # Hooks only run on commit, not against all files whenever the shell starts
    tasks."devenv:git-hooks:run".before = lib.mkForce [];
    git-hooks.hooks = mkIf cfgLib.enable {
      check-merge-conflicts.enable = true;
      no-commit-to-branch = {
        enable = true;
        settings.branch = ["main" "master" "production"];
        always_run = true;
      };
    };
  };
}
