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
          name = config.env.DB_USERNAME;
          password = config.env.DB_PASSWORD;
          ensurePermissions = {
            "*.*" = "ALL PRIVILEGES";
          };
        }
      ];
      initialDatabases = [
        {
          name = config.env.DB_DATABASE;
        }
      ];
      settings = {
        mysqld = {
          port = config.env.DB_PORT;
          bind-address = config.env.DB_HOST;
        };
      };
    };

    # Email testing
    mailpit = {
      enable = true;
      smtpListenAddress = "${config.env.MAIL_HOST}:${config.env.MAIL_PORT}";
      uiListenAddress = "${config.env.MAIL_HOST}:${config.env.MAIL_UI_PORT}";
    };

    # Adminer for accessing the database (localhost:8080 by default)
    adminer = {
      enable = true;
      package = pkgs.adminerevo;
    };
  };
}