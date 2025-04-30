{ pkgs, lib, config, ... }:

let 
 dotenvDefaults = {
  SERVER_HOST = "127.0.0.1";
  SERVER_PORT = "18000";

  APP_NAME = "lokale-beste-schule";
  APP_DEBUG = "true";
  APP_ENV = "local";
  VITE_APP_ENV = config.env.APP_ENV;
  APP_URL = "http://${config.env.SERVER_HOST}:${config.env.SERVER_PORT}";
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
  MAIL_HOST = config.env.SERVER_HOST;
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
  languages = {
    php = {
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
          memory_limit = 1024M

          [XDebug]
          xdebug.mode=debug
          xdebug.start_with_request=yes
          xdebug.client_port=${config.env.XDEBUG_PORT}
        '';
      };
    };

    javascript = {
      enable = true;
      package = pkgs.nodejs_18;
      npm.enable = true;
    };

    typescript.enable = true;
  };

  # --- ALL PROCESSES STARTED WITH `devenv up`
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

    # Adminer for accessing the database (localhost:8080 by default)
    adminer = {
      enable = true;
      package = pkgs.adminerevo;
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
        #!/usr/bin/env nu

        # --- Install dependencies
        composer install
        npm install

        # --- Create the laravel passport
        php artisan passport:install
        
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

    api = {
      description = ''
        A script that conveniently calls the API of a local or remote instance.
      '';
      package = pkgs.nushell;
      binary = "nu";
      exec = ''
        # Ensure that the input starts with a slash
        def ensure_leading_slash [] {
          if ($in | str starts-with "/") { echo $in } else { echo $"/($in)" }
        }
        # Apply the given `func` if `ok` is true and just pass the input if not
        def maybe_apply [ ok: bool func: closure ] {
          if $ok { do $func $in } else { $in }
        }
        # Main function
        def main [ path: string ...select: cell-path --token (-t): string --explore (-x) --host: string = "http://localhost:8000" --raw (-r) --dbdebug (-d) ] {
          # Extract token from environment if not passed explicitely
          let token = if $token != null {
            echo $token
          } else if "TOKEN_L2" in $env {
            echo $env.TOKEN_L2
          } else {
            error make { msg: "TOKEN_L2 environment variable is not set. Provide a token with `--token TOKEN`" label: { span: (metadata $token).span, text: "--token TOKEN not provided" }}
          }
          # Construct the url
          let url = $"($host)/api($path | ensure_leading_slash)"
          # Fetch from the api!
          http get $url --allow-errors --full --headers [
              "Accept" "application/json"
              "Authorization" $"Bearer ($token)"
            ]
          | if $in.status == 200 {
              $in.body.data | maybe_apply ($select != null) { select ...$select }
            } else {
              $in.body | maybe_apply ("trace" in $in) { 
                update trace { 
                  # Only include entries where a file is specified and where the file is not in vendor package
                  where {
                    |row| ("file" in $row) and $row.file !~ "/vendor/"
                  }
                  # remove the PWD from the path to the file
                  | each {
                    |row| $row | update file { str replace $"($env.PWD)/" "" }
                  }
                }
              }
              # same as above for main file of error
              | maybe_apply ("file" in $in) { update file { str replace $"($env.PWD)/" "" } }
            }
          # remove the debug section from the response if not specified
          | maybe_apply (not $dbdebug) { reject "debug" }
          | maybe_apply $explore { explore }
          | maybe_apply $raw {to json}
        }
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
  enterShell = ''
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
    ${lib.pipe config.scripts [
      # Only show scripts with a description
      (lib.attrsets.filterAttrs (_: script: script.description != ""))

      # Format the filtered set to a string showing name and description
      (lib.foldlAttrs (acc: name: value: acc + ''
        - `${name}` - ${config.scripts.${name}.description}
      '') "")
    ]}
    '\
    | glow
  '';

  pre-commit.hooks = {
    check-added-large-files.enable = true;
    check-merge-conflicts.enable = true;
    shellcheck.enable = true;
    shfmt.enable = true;
    no-commit-to-branch = {
      enable = true;
      settings.branch = [ "main" "master" "production" ];
      always_run = true;
    };
    check-types-ts = {
      enable = true;
      name = "check-types-ts";
      description = "does some validation on types.ts, like type sorting order";
      files = "^resources/js/types\.ts$";
      entry = let
        pkg = pkgs.writeShellApplication {
          name = "check-types-ts";
          runtimeInputs = [pkgs.ripgrep pkgs.coreutils];
          text = ''
            rg '^export (type|interface) (\w+)' --only-matching --replace '$2' --no-filename "$${@}" | sort --check
          '';
        };
      in
        lib.getExe pkg;
    };
  };

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
