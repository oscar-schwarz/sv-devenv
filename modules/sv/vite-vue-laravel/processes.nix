{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;

  cfg = config.sv.vite-vue-laravel;
in mkIf cfg.enable {
  processes = if cfg.sail.enable then 
  
  # --- SAIL 
  {
    dockerd = mkIf cfg.sail.dockerd.enable {
      inherit (cfg.sail.dockerd) exec;
      process-compose = {inherit (cfg.sail.dockerd) ready_log_line;};
    };
    sail = {
      exec = "sail build;sail up";
      process-compose = {
        shutdown = {
          command = "sail down";
          timeout = "10s"; # Allow time for sail down to complete
        };
        ready_log_line = "success: php entered RUNNING state";
        depends_on.dockerd.condition = mkIf cfg.sail.dockerd.enable "process_log_ready";
      };
    };
    vite = {
      exec = "sail npm install; sail npm run dev -- --port ${config.envFile.VITE_PORT}";
      process-compose = {
        availability.restart = "on_failure";
        depends_on.sail.condition = "process_log_ready";
      };
    };
  }

  else 
  
  # --- NATIVE
  {
    laravel.exec = "php artisan serve";
    laravel-worker.exec = "php artisan queue:work";
    vite.exec = "npm run dev -- --port ${config.envFile.VITE_PORT}";
  };
}