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
  # Custom processes started with devenv up
  processes = getAttr cfg.repo {

    # --- REPO: WEB
    web = getAttr cfg.web.mode {

      # --- MODE: NATIVE
      native = {
        laravel.exec = "php artisan serve";
        laravel-worker.exec = "php artisan queue:work";
        vite.exec = "npm run dev -- --port ${env.VITE_PORT}";
      };

      # --- MODE: CONTAINER
      container = {
        container-engine = mkIf cfg.web.container-engine-daemon.enable {
          inherit (cfg.web.container-engine-daemon) exec;
        };
        sail = {
          exec = "sail up";
          process-compose.shutdown = {
            command = "sail down";
            timeout = "10s"; # Allow time for sail down to complete
          };
        };
        vite = {
          exec = "sail npm install; sail npm run dev -- --port ${env.VITE_PORT}";
          process-compose.availability.restart = "on_failure";
        };
      };
    };

    # --- REPO: APP
    app = {
      nuxt.exec = "npm run dev -- --port 3000 --debug";
    };
  };
}