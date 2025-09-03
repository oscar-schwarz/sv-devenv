{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (builtins) readFile;
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.strings) optionalString;
  inherit (lib.attrsets) optionalAttrs;

  cfg = config.sv.laravel-sail;
in {
  options.sv.laravel-sail = {
    enable = mkEnableOption "a project that uses Laravel Sail as the backend";
    flavor = lib.mkOption {
      type = with lib.types; nullOr (enum ["beste" "plan" "planer"]);
      default = null;
      description = "The flavor of Laravel Sail configuration to use";
    };
    nodejs-frontend = {
      enable = mkEnableOption "Node.js frontend support for Laravel Sail projects";
      needsGithubSSH = mkEnableOption "npm install needs to fetch from private repositories";
    };
  };
  config = mkIf cfg.enable {
    packages = with pkgs; [
      podman
      podman-compose
      (writeShellScriptBin "docker" "${pkgs.podman}/bin/podman \"$@\"")
      mycli
    ];

    sv.extraWelcomeText =
      if cfg.flavor != null
      then "**Flavor:** `${cfg.flavor}`"
      else "";

    env = {
      # This allows podman to pull short names such as caddy:2-alpine
      CONTAINERS_CONF = pkgs.writeTextFile {
        name = "containers.conf";
        text =
          /*
          toml
          */
          ''
            unqualified-search-registries = ["docker.io"]
          '';
      };
      PODMAN_COMPOSE_WARNING_LOGS = "false";
    };

    enterShell =
      /*
      bash
      */
      ''
        # Add scripts from vendor/bin to path
        export PATH="$PATH:$DEVENV_ROOT/vendor/bin"

        # Setup podman to accept anything (yolo)
        if [ ! -e ~/.config/containers/policy.json ]; then
          echo '{}' > ~/.config/containers/policy.json
        fi
        podman image trust set default --type accept
      '';

    languages.php = {
      enable = true;
      package = pkgs.php83;
      packages.composer = pkgs.php83Packages.composer;
    };

    scripts = {
      api = {
        description = ''
          A script that conveniently calls the API of a local or remote instance.
        '';
        package = pkgs.nushell;
        binary = "nu";
        exec = readFile ../../../scripts/api.nu;
      };
      laravel-sail-install = {
        description = ''
          Sets the environment up for development on laravel sail. Do this before using `devenv up` the first time.
        '';
        exec =
          /*
          bash
          */
          ''
            set -e

            # Fix permission issues with podman
            if [ ! -d node_modules ]; then
              mkdir node_modules
            fi
            set +e
            chmod 777 . -R
            set -e
            git checkout -- . # remove permission changes from tracked files
            # reapply the patches
            ${config.lib.patchCommands}

            # Install dependencies and start container
            composer install
            sail up --detach
            ${optionalString cfg.nodejs-frontend.enable
              /*
              bash
              */
              ''
                ${optionalString cfg.nodejs-frontend.needsGithubSSH
                  /*
                  bash
                  */
                  ''
                    podman compose exec laravel.test bash -c '
                      echo "yes" | ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
                      eval "$(ssh-agent -s)"
                      ssh-add ~/.ssh/id_ed25519
                    '
                    pubkey=$(podman compose exec laravel.test bash -c 'cat ~/.ssh/id_ed25519.pub')

                    echo "
                      This project needs access to install NPM packages that are located in private GitHub repositories.
                      To make this possible navigate to https://github.com/settings/keys and add this SSH public key:
                    " | glow
                    podman compose exec laravel.test bash -c 'cat ~/.ssh/id_ed25519.pub'

                    echo "
                      If you are done hit ENTER.
                    " | glow
                    read
                  ''}
                sail npm clean-install
              ''}

            # Generate APP_KEY
            sail php artisan key:generate

            # Migrate Database
            sail php artisan migrate

            sail down

            echo -e '
              **Setup done!**
              If the application has a seeder you can seed the database with:
              ```bash
              sail php artisan db:seed
              ```

              Also you may now use `devenv up` to start the application.
            ' | glow
          '';
      };
      sql = {
        description = ''
          Connect to the database.
        '';
        exec =
          /*
          bash
          */
          ''
            mycli \
              --port ${config.envFile.DB_PORT or "3306"} \
              --user ${config.envFile.DB_USERNAME or ""} \
              --password ${config.envFile.DB_PASSWORD or ""} \
              --database ${config.envFile.DB_DATABASE} \
              --auto-vertical-output \
              "$@"
          '';
      };
    };

    processes =
      {
        sail-up = {
          exec = ''
            sail down
            sail build
            sail up --detach
          '';
          process-compose = {
            is_daemon = true;
            shutdown = {
              command = "sail down";
              timeout_seconds = 10; # Allow time for sail down to complete
            };
          };
        };
        queue-worker = {
          exec = "sail php artisan queue:work";
          process-compose = {
            availability.restart = "on_failure";
          };
        };
      }
      // (optionalAttrs cfg.nodejs-frontend.enable {
        vite = {
          exec = "sail npm run dev";
          process-compose = {
            availability.restart = "on_failure";
          };
        };
      });
  };
}
