{ pkgs, lib, config, ... }: let 
  inherit (builtins) getAttr;
  inherit (lib) mkEnableOption mkPackageOption mkOption types mkIf;
  
  cfg = config.beste-schule;
  localLib = config.lib.beste-schule;
in {
  options = {
    beste-schule = {
      enable = mkEnableOption "beste-schule module";
      repo = mkOption {
        description = ''
          For which repository the devenv shell is used.
        '';
        default = "web";
        type = types.enum [ "web" "app" ];
      };
      web = {
        mode = mkOption {
          description = ''
            Which way the instance is set up. Either dockerized or running natively.
          '';
          type = types.enum [ "container" "native" ];
          default = "native";
        };
        container-engine-daemon = {
          enable = mkEnableOption ''
            a container engine (docker or podman) daemon as a process. Has only an effect in mode "container". 
            Removes the need to have container engine running on the system.
          ''; 
          package = mkPackageOption pkgs "podman";
          exec = mkOption {
            description = ''
              The command to launch the daemon.
            '';
            default = "dockerd-rootless";
            type = types.str;
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Disable the cachix cache by default
    cachix.enable = lib.mkDefault false;

    # Some utility functions
    lib.beste-schule = {
      isWeb = (cfg.enable && cfg.repo == "web");
      isApp = (cfg.enable && cfg.repo == "app");
      isNative = (cfg.enable && cfg.web.mode == "native");
      isContainer = (cfg.enable && cfg.web.mode == "container");
    };

    # Define a welcome message when opening the shell
    enterShell = ''
      # --- Show available scripts and a welcome message
      echo -e '
      # Welcome to the beste-schule dev shell

      **Repo** `${cfg.repo}`

      ${if localLib.isWeb then "**Mode** `${cfg.web.mode}`" else ""}

      **Available commands:**
      - `devenv up` - starts all necessary services
      ${lib.pipe config.scripts [
        # Only show scripts with a description
        (lib.attrsets.filterAttrs (_: script: script.description != ""))

        # Format the filtered set to a string showing name and description
        (lib.foldlAttrs (acc: name: value: acc + ''
          - `${name}` - ${config.scripts.${name}.description}
        '') "")
      ]}
      '\
      | ${lib.getExe pkgs.glow} --width 0

      # --- Add scripts from vendor/bin to path
      export PATH="$PATH:$DEVENV_ROOT/vendor/bin"

      # --- Docker needs that to function properly
      export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock

      # --- Little hack to fix permissions in laravel storage
      if [ "$(stat -c "%a" $DEVENV_ROOT)" != "777" ]; then
        echo "The repository directory does not have the 777 permission, without it the sail user in the container cannot write to it. Sudo is required to add it."
        echo "You can change that by running: 'sudo chmod -R 777 ."
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

    # Additional packages
    packages = getAttr cfg.repo {
      web = with pkgs; [
        podman-compose
        docker
      ];
      app = [];
    };
  };
}