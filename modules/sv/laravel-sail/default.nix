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
          Setup environment for laravel sail. Do this before `devenv up` and to update deps.
        '';
        exec =
          /*
          bash
          */
          ''
            set -e
            # Install dependencies and start container
            composer install

            sail up --detach

            # Fix permission issues with podman
            if [ ! -d node_modules ]; then
              mkdir node_modules
            fi
            sail-root-run chmod 777 . -R

            ${optionalString cfg.nodejs-frontend.enable
              /*
              bash
              */
              ''
                while true; do
                  set +e
                  sail npm install
                  exit_code="$?"
                  set -e

                  if [ $exit_code -eq 0 ]; then
                    break
                  elif [ $exit_code -eq 128 ]; then
                    sail-root-run chown sail -R /home/sail/.ssh
                    sail-root-run chmod 700 -R /home/sail/.ssh
                    sail-run bash -c 'echo "yes" | ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""'

                    echo "
                      This project needs access to install NPM packages that are located in private GitHub repositories.
                      To make this possible navigate to https://github.com/settings/keys and add this SSH public key:
                    " | sed 's/^[ ]*//' | glow
                    sail-run bash -c 'cat ~/.ssh/id_ed25519.pub'

                    echo "
                      When you are done hit ENTER.
                    " | sed 's/^[ ]*//' | glow
                    read
                  else
                    exit
                  fi
                done
              ''}

            # Generate APP_KEY
            sail php artisan key:generate

            # Migrate Database
            sail php artisan migrate

            git checkout -- . # remove permission changes from tracked files

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
              --port "${config.envFile.DB_PORT or "3306"}" \
              --user "${config.envFile.DB_USERNAME or ""}" \
              --password "${config.envFile.DB_PASSWORD or ""}" \
              --database "${config.envFile.DB_DATABASE}" \
              --auto-vertical-output \
              "$@"
          '';
      };
      sail-run = {
        description = ''
          `sail run` for laravel sail versions pre v1.41.0
        '';
        exec = ''
          sail exec --user sail laravel.test "$@"
        '';
      };
      sail-root-run = {
        description = ''
          `sail-run` as root user.
        '';
        exec = ''
          sail exec laravel.test "$@"
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
