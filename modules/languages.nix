{  pkgs, lib, config, ... }: let
  inherit (lib) mkIf;

  cfg = config.beste-schule;

  isNative = cfg.mode == "native";
  isContainer = cfg.mode == "container";
in mkIf cfg.enable {
  languages = {
    php = {
      enable = true;
      # advanced php setup only needed in native mode
      package = mkIf isNative pkgs.php.buildEnv {
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
      npm.enable = true;
    };

    typescript.enable = true;
  };
}