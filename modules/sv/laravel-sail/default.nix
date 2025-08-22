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
    ];
    
    enterShell = /*bash*/''
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
        exec = /*bash*/''
          set -e
          
          # Fix permission issues with podman
          if [ ! -d node_modules ]; then
            mkdir node_modules
          fi
          set +e
          chmod 777 . -R
          set -e
          git checkout -- . # remove permission changes from tracked files
          
          # Install dependencies and start container
          composer install
          devenv up podman-service --detach
          sleep 1
          sail up --detach
          ${optionalString cfg.nodejs-frontend.enable "sail npm clean-install"}

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
    };

    processes = {  
      sail-up = {
        exec = ''
          sail down
          sail build
          sail up --detach
        '';
        process-compose = {
          shutdown = {
            command = "sail down";
            timeout = "5s"; # Allow time for sail down to complete
          };
        };
      };
      queue-worker = {
        exec = "sail php artisan queue:work";
        process-compose = {
          depends_on.sail-up.condition = "process_completed_successfully";
          availability.restart = "on_failure";
        };
      };
    } // (optionalAttrs cfg.nodejs-frontend.enable {
      vite = {
        exec = "sail npm run dev";
        process-compose = {
          depends_on.sail-up.condition = "process_completed_successfully";
          availability.restart = "on_failure";
        };
      };
    });
  };
}
