{ pkgs, lib, config, ... }:

let 
 dotenvDefaults = rec {
  SERVER_HOST = "127.0.0.1";
  SERVER_PORT = "18000";

  APP_NAME = "lokale-beste-schule";
  APP_DEBUG = "true";
  APP_ENV = "local";
  VITE_APP_ENV = APP_ENV;
  APP_URL = "http://${SERVER_HOST}:${SERVER_PORT}";
  APP_KEY = "base64:Igl3VDbdMSWnCDABL7k9ioK8hJ1EKgM25kh6vnxUntQ="; # This has to be set

  TOKEN_VALID = "14";
  TOKEN_LENGTH = "16";

  SESSION_LIFETIME = "30";
  MIX_SESSION_LIFETIME = "30";

  API_VERSION = "0.3";

  RATE_LIMIT = "60";

  LOG_CHANNEL = "stack";
  LOG_STACK_CHANNELS = "daily";
  LOG_LEVEL = "debug"; #emergency, alert, critical, error, warning, notice, info, or debug

  DB_CONNECTION = "mysql";
  DB_HOST = "127.0.0.1";
  DB_PORT = "13306";
  DB_DATABASE = "beste_schule";
  DB_USERNAME = "user";
  DB_PASSWORD = "user";

  PLAN_SCHULE_URL = "http://plan.schule";

  REPORT_DISPATCH_ASYNC = "true";

  REPORT_BYPASS_CACHE = "false";

  QUEUE_CONNECTION = "database";

  # Mailpit
  MAIL_MAILER = "smtp";
  MAIL_HOST = SERVER_HOST;
  MAIL_UI_PORT = "18025";
  MAIL_PORT = "11025";
  MAIL_USERNAME= "null";
  MAIL_PASSWORD= "null";
  MAIL_ENCRYPTION= "null";
  MAIL_FROM_ADDRESS= "noreply@schulverwalter.de";
  MAIL_SUPPORT = "support@schulverwalter.test";
  MAIL_SALES = "vertrieb@schulverwalter.test";
  MAIL_FROM_NAME = "Schulverwalter";

  # Custom for this nix file
  XDEBUG_PORT = "19003";
  VITE_PORT = "15734";
};
in {
  # --- DOTENV ---
  # Make the values from the dotenv available in `config.env`
  # But this also makes values from `config.env` available as env variables from the shell
  dotenv.enable = true;

  # Declare the defaults of the env
  env = lib.attrsets.mapAttrs (key: value: lib.mkOptionDefault value) dotenvDefaults;

  # --- LANGUAGLES SETUP ---
  # Configure PHP
  languages.php = {
    enable = true;
    package = pkgs.php.buildEnv {
      extensions = { enabled, all }: enabled ++ (with all; [
        xdebug
        dom
        curl
        bcmath
        pdo
        tokenizer
        mbstring
        mysqli
      ]);
      extraConfig = ''
        max_execution_time = 120
        memory_limit = 256M

        [XDebug]
        xdebug.mode=debug
        xdebug.start_with_request=yes
        xdebug.client_port=${config.env.XDEBUG_PORT}
      '';
    };
  };

  # Configure Node
  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_18;
    npm.enable = true;
  };


  # --- ALL PROCESSES STARTED WITH `devenv up`
  process.manager.implementation = "overmind"; # for some reason, npm wont shut down with process-compose
  services = {
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
  };

  # custom processes
  processes = {
    laravel.exec = "php artisan serve";
    laravel-worker.exec = "php artisan queue:work";
    vite.exec = "npm run dev -- --port ${config.env.VITE_PORT}";
  };


  # --- SCRIPTS ---
  scripts = {
    beste-schule-install = {
      description = ''
        Installs all dependencies, creates, migrates and seeds the database.
      '';
      exec = ''
        # --- Install dependencies
        composer install
        npm install
        
        # --- Start the sql service
        devenv up mysql --detach
        wait-for-port ${config.env.DB_PORT}
        devenv up mysql-configure --detach
        
        # --- Start Laravel
        devenv up artisan --detach
        wait-for-port ${config.env.SERVER_PORT}
        
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
          --user=${config.env.DB_USERNAME} \
          --password=${config.env.DB_PASSWORD} \
          --database=${config.env.DB_DATABASE} \
          "$@"
      '';
    };

    devshell-fetch = {
      description = ''
        Download the latest version of the beste.schule devenv environment from GitHub.
      '';
      exec = ''
        # Fetch all three files
        curl https://raw.githubusercontent.com/oscar-schwarz/devenv-beste-schule/refs/heads/main/devenv.lock \
          > devenv.lock
        curl https://raw.githubusercontent.com/oscar-schwarz/devenv-beste-schule/refs/heads/main/devenv.nix \
          > devenv.nix
        curl https://raw.githubusercontent.com/oscar-schwarz/devenv-beste-schule/refs/heads/main/devenv.yaml \
          > devenv.yaml
      '';
    };
  };


  # --- SCRIPT ON ENTERING THE DEV SHELL ---
  # Greeting on entering the shell
  enterShell = let
    descriptionsOf = lib.lists.foldl (acc: name: acc + ''
      - `${name}` - ${config.scripts.${name}.description}
    '') "";
  in ''
    # --- Making sure that devenv files are excluded from git history
    excludeGit=".git/info/exclude"
    files=".devenv devenv.nix devenv.yaml devenv.lock .devenv.flake.nix"
    for file in $files; do
      if ! grep -q "$file" "$excludeGit"; then
        echo Adding "$file" to "$excludeGit"
        echo "$file" >> "$excludeGit"
      fi
    done

    # --- Add a declaration to the .env file if a variable is missing using the defaults from above
    ${lib.attrsets.foldlAttrs (acc: name: value: acc + ''
    if ! grep -q ${name} .env; then
      echo '${name}=${config.env.${name}}' >> .env
      echo ${name} not found in .env file. Adding it with a default value.
    fi
    '') "" dotenvDefaults}

    # --- Show a welcome message
    echo -e '
    # Welcome to the beste.schule developer shell

    **Available commands:**
    - `devenv up` - starts all necessary services
    ${descriptionsOf ["beste-schule-install" "sql" "devshell-fetch"]}
    '\
    | glow
  '';


  # --- ADDITIONAL PACKAGES ---
  packages = with pkgs; [
    glow # Terminal markdown
    curl # Fetch stuff

    # Waits for a specific port to be openend
    (pkgs.writeShellApplication {
      name = "wait-for-port";
      runtimeInputs = [ pkgs.netcat ];
      text = ''
        while ! nc -z localhost "$1"; do
          sleep 0.1
        done
      '';
    })
  ];

  # --- MISC ---
  # Disable cachix (disable the warning that the user might not be a trusted user of the nix store)
  cachix.enable = false;
}
