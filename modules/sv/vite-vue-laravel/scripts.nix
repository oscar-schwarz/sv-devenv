{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (builtins) readFile;
  inherit (lib) mkIf;

  cfg = config.sv.vite-vue-laravel;
in mkIf cfg.enable {
  scripts = {
    # --- INTERFACES
    api = {
      description = ''
        A script that conveniently calls the API of a local or remote instance.
      '';
      package = pkgs.nushell;
      binary = "nu";
      exec = readFile ../../../scripts/api.nu;
    };
    sql = {
      description = ''
        Opens a database connection to the database logged in as the database user.
      '';
      exec = ''
        mariadb \
          --user=${config.env.DB_USERNAME} \
          --password=${config.env.DB_PASSWORD} \
          --database=${config.env.DB_DATABASE} \
          "$@"
      '';
    };
    beste-schule-install = {
      description = ''
        Installs all dependencies, creates, migrates and seeds the database.
      '';
      exec = ''
        # --- find out with which program artisan can be controlled
        phpOrSail=${if cfg.sail.enable then "sail" else "php"}

        # --- Install dependencies
        if [ ${!cfg.sail.enable} ]; then
          composer install
          npm install
        fi

        if [ ${cfg.sail.enable} ]; then
          # --- Start container
          devenv up --detach
        else
          # --- Start the sql service
          devenv up mysql --detach
          devenv up mysql-configure --detach
          wait-for-port ${config.env.DB_PORT}
          
          # --- Start Laravel
          devenv up artisan --detach
        if

        # --- Wait until everything started
        wait-for-port ${config.env.APP_PORT}

        # --- Generate keys
        $phpOrSail artisan key:generate
        
        # --- Migrate the database
        $phpOrSail artisan migrate

        # --- Seed the database (Only if a seeder exists)
        if [ -f "database/seeders/SchoolSeeder.php" ]; then
          $phpOrSail artisan db:seed
        fi

        # --- Stop all ran processes again
        devenv processes stop
      '';
    };

    # --- UTILITY
    wait-for-port.exec = ''
      while ! ${pkgs.netcat}/bin/nc -z localhost "$1"; do
        sleep 0.1
      done
    '';
  };
}