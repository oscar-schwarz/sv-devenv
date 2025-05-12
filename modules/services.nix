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
  # Services started with devenv up
  services = getAttr cfg.repo {

    # --- REPO: WEB
    web = getAttr cfg.web.mode {

      # --- MODE: NATIVE
      native = {
        # Database
        mysql = {
          enable = true;
          package = pkgs.mariadb;
          ensureUsers = [
            {
              name = env.DB_USERNAME;
              password = env.DB_PASSWORD;
              ensurePermissions = {
                "*.*" = "ALL PRIVILEGES";
              };
            }
          ];
          initialDatabases = [
            {
              name = env.DB_DATABASE;
            }
          ];
          settings = {
            mysqld = {
              port = env.DB_PORT;
              bind-address = env.DB_HOST;
            };
          };
        };

        # Email testing
        mailpit = {
          enable = true;
          smtpListenAddress = "${env.MAIL_HOST}:${env.MAIL_PORT}";
          uiListenAddress = "${env.MAIL_HOST}:${env.MAIL_UI_PORT}";
        };

        # Adminer for accessing the database (localhost:8080 by default)
        adminer = {
          enable = true;
          package = pkgs.adminerevo;
        };
      };

      # --- MODE: CONTAINER
      container = {

      };
    };

    # --- REPO: APP
    app = {

    };
  };
}