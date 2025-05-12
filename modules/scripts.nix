{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (builtins) getAttr readFile;
  inherit (lib) mkIf;

  env = config.subEnv;
  cfg = config.beste-schule;
  localLib = config.lib.beste-schule;

in mkIf cfg.enable {
  # Custom processes started with devenv up
  scripts = 
  # shared among all repos
  {
    api = {
      description = ''
        A script that conveniently calls the API of a local or remote instance.
      '';
      package = pkgs.nushell;
      binary = "nu";
      exec = readFile ../scripts/api.nu;
    };
  }
  # Per repo
  // (getAttr cfg.repo {

    # --- REPO: WEB
    web = {
      beste-schule-install = {
        description = ''
          Installs all dependencies, creates, migrates and seeds the database.
        '';
        exec = ''
          # --- Install dependencies
          composer install
          npm install

          # --- Create the laravel passport
          php artisan passport:install
          
          # --- Start the sql service
          devenv up mysql --detach
          wait-for-port ${env.DB_PORT}
          devenv up mysql-configure --detach
          
          # --- Start Laravel
          devenv up artisan --detach
          wait-for-port ${env.SERVER_PORT}
          
          # --- Migrate the database
          php artisan migrate

          # --- Seed the database (Only if a seeder exists)
          if [ -f "database/seeders/SchoolSeeder.php" ]; then
            php artisan db:seed
          fi

          # --- Stop all ran processes again
          devenv processes stop
        '';
      };
      sql = {
        description = ''
          Opens a database connection to the database logged in as the database user.
        '';
        exec = ''
          mariadb \
            --user=${env.DB_USERNAME} \
            --password=${env.DB_PASSWORD} \
            --database=${env.DB_DATABASE} \
            "$@"
        '';
      };
      wait-for-port.exec = ''
        while ! ${pkgs.netcat}/bin/nc -z localhost "$1"; do
          sleep 0.1
        done
      '';
    };

    # --- REPO: APP
    app = {

    };
  });
}