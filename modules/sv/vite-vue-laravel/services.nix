{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;

  cfg = config.sv.vite-vue-laravel;
in mkIf cfg.enable {
  services = mkIf (!cfg.sail.enable) { # not needed when using container
    # Database
    mysql = {
      enable = true;
      package = pkgs.mariadb;
      ensureUsers = [
        {
          name = config.envFile.DB_USERNAME;
          password = config.envFile.DB_PASSWORD;
          ensurePermissions = {
            "*.*" = "ALL PRIVILEGES";
          };
        }
      ];
      initialDatabases = [
        {
          name = config.envFile.DB_DATABASE;
        }
      ];
      settings = {
        mysqld = {
          port = config.envFile.DB_PORT;
          bind-address = config.envFile.DB_HOST;
        };
      };
    };

    # Email testing
    mailpit = {
      enable = true;
      smtpListenAddress = "${config.envFile.MAIL_HOST}:${config.envFile.MAIL_PORT}";
      uiListenAddress = "${config.envFile.MAIL_HOST}:${config.envFile.MAIL_UI_PORT}";
    };

    # Adminer for accessing the database (localhost:8080 by default)
    adminer = {
      enable = true;
      package = pkgs.adminerevo;
    };
  };
}