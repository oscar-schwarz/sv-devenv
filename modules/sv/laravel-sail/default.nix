{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (builtins) readFile toJSON;
  inherit (lib) mkEnableOption mkIf mkMerge;
  inherit (lib.attrsets) optionalAttrs;

  cfg = config.sv.laravel-sail;
  appUser = config.envFile.APP_USER or "sail";

  # Always-on Xdebug: every request goes through the debugger when a client listens on port 9003
  xdebugIni = pkgs.writeText "zz-sv-devenv-xdebug.ini" ''
    xdebug.mode=debug,develop
    xdebug.start_with_request=yes
    xdebug.client_host=host.docker.internal
    xdebug.client_port=9003
    ; silences "Could not connect to debugging client" when no client listens
    xdebug.log_level=0
  '';

  # Switches laravel.test to the FrankenPHP + Octane runtime that the project ships in sail/runtimes/frankenphp
  octaneComposeOverride = {
    services."laravel.test" = {
      build.context = "./sail/runtimes/frankenphp";
      image = "sail-frankenphp-8.5/app";
      ports = ["\${CADDY_ADMIN_PORT:-2019}:2019"];
      environment = {
        OCTANE_SERVER = "frankenphp";
        # the queue runs as a devenv process instead
        SAIL_ENABLE_QUEUE_WORKER = "false";
        XDEBUG_MODE = "debug,develop";
      };
      volumes = [
        ".:/app:z"
        "${xdebugIni}:/usr/local/etc/php/conf.d/zz-sv-devenv-xdebug.ini:ro"
      ];
    };
  };
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
    composeOverride = lib.mkOption {
      type = (pkgs.formats.json {}).type;
      default = {};
      description = "Content of a local, git-excluded docker-compose.override.yml that compose merges into docker-compose.yml";
    };
    octane = {
      enable = mkEnableOption "the FrankenPHP + Octane runtime with always-on Xdebug through a local docker-compose.override.yml";
    };
  };
  config = mkIf cfg.enable (mkMerge [
    {
      packages = with pkgs; [
        podman
        podman-compose
        (writeShellScriptBin "docker" "${pkgs.podman}/bin/podman \"$@\"")
        # mycli pins sqlglot to an older major version than nixpkgs ships
        (mycli.overridePythonAttrs (prev: {
          pythonRelaxDeps = ["sqlglot"] ++ (prev.pythonRelaxDeps or []);
        }))
      ];

      sv.extraWelcomeText =
        if cfg.flavor != null
        then "**Flavor:** `${cfg.flavor}`"
        else "";

      env = {
        # This allows podman to pull short names such as caddy:2-alpine
        CONTAINERS_REGISTRIES_CONF = pkgs.writeTextFile {
          name = "registries.conf";
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
          export PATH="vendor/bin:$PATH"

          # Setup podman to accept anything (yolo)
          mkdir -p ~/.config/containers
          if [ ! -e ~/.config/containers/policy.json ]; then
            echo '{}' > ~/.config/containers/policy.json
          fi
          podman image trust set default --type accept

          # Warn about keys from .env.example that are missing in .env
          if [ ! -f .env ]; then
            echo "> No .env file found, create one with: cp .env.example .env"
          else
            missingCount="$(env-check | wc -l)"
            if [ "$missingCount" -gt 0 ]; then
              echo "> .env is missing $missingCount keys from .env.example, list them with: env-check"
            fi
          fi
        '';

      languages.php = {
        enable = true;
        package = pkgs.php84;
        packages.composer = pkgs.php84Packages.composer;
      };

      scripts = {
        env-check = {
          description = ''
            Lists keys from `.env.example` that are missing in `.env`.
          '';
          exec = ''
            [ -f .env ] && [ -f .env.example ] || exit 0
            comm -23 \
              <(grep -oE '^[A-Za-z0-9_]+=' .env.example | tr -d '=' | sort -u) \
              <(grep -oE '^[A-Za-z0-9_]+=' .env | tr -d '=' | sort -u)
          '';
        };
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
          exec = "bash ${../../../scripts/laravel-sail-install.sh}";
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
                --port "${config.envFile.FORWARD_DB_PORT or "3306"}" \
                --user "${config.envFile.DB_USERNAME or ""}" \
                --password "${config.envFile.DB_PASSWORD or ""}" \
                --database "${config.envFile.DB_DATABASE or ""}" \
                --auto-vertical-output \
                "$@"
            '';
        };
        sail-run = {
          description = ''
            Run a command in the app container as the user the app runs as (`APP_USER`).
          '';
          exec = ''
            sail exec --user ${appUser} laravel.test "$@"
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

      process.manager.implementation = "process-compose";

      processes =
        {
          sail-up = {
            exec = ''
              sail down
              sail build
              sail up
            '';
          };
          # queue:listen boots the framework for every job, so code changes apply without a restart
          queue-worker = {
            exec = "sail-run php artisan queue:listen --queue=print,print-bulk,default --tries=3";
            restart = {
              on = "on_failure";
              max = 99999;
            };
          };
        }
        // (optionalAttrs cfg.nodejs-frontend.enable {
          vite = {
            exec = "sail npm run dev";
            restart = {
              on = "on_failure";
              max = 99999;
            };
          };
        });
    }

    (mkIf (cfg.composeOverride != {}) {
      sv.gitExclude = ["docker-compose.override.yml"];

      # A copy instead of a symlink, so that compose resolves relative paths against the project
      enterShell = let
        file = pkgs.writeText "docker-compose.override.yml" (toJSON cfg.composeOverride);
      in ''
        if ! cmp -s ${file} docker-compose.override.yml; then
          install -m 644 ${file} docker-compose.override.yml
          echo "> Updated docker-compose.override.yml, apply it with: sail build && sail up -d"
        fi
      '';
    })

    (mkIf cfg.octane.enable {
      sv.laravel-sail.composeOverride = octaneComposeOverride;

      # start_with_request only triggers when a worker boots, this connects to the debugger on every request
      patches.octaneXdebug = {
        enable = true;
        diffFile = ../../../diff/octane-xdebug.diff;
        patchedFile = {
          localPath = "vendor/laravel/octane/bin/frankenphp-worker.php";
          isTracked = false;
        };
      };

      sv.extraWelcomeText = lib.mkAfter ''

        **Octane:** workers reload on file changes (`--watch`), force it with `octane-reload`.
        **Xdebug:** always on, every request connects to port 9003. Path mapping: `/app` → project directory.
      '';

      scripts.octane-reload = {
        description = ''
          Reload the Octane workers.
        '';
        exec = ''
          sail-run php artisan octane:reload
        '';
      };
    })
  ]);
}
