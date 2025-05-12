{  pkgs, lib, config, ... }: let
  inherit (builtins) getAttr;
  inherit (lib) mkIf;

  cfg = config.beste-schule;
  localLib = config.lib.beste-schule;

in mkIf cfg.enable {
  languages = {

    php = mkIf localLib.isWeb {
      enable = true;
      # advanced php setup only needed in native mode
      package = mkIf localLib.isNative (pkgs.php82.buildEnv {
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
      });
    };

    javascript = {
      enable = true;
      npm.enable = true;
    };

    typescript.enable = true;
  };
}