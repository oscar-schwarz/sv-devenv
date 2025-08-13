{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;

  cfg = config.sv.laravel-sail;
in mkIf cfg.enable {
  languages = {
    php = {
      enable = true;
      # advanced php config not needed in sail mode
      package = mkIf (!cfg.sail.enable) (pkgs.php83.buildEnv {
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
          xdebug.client_port=${config.envFile.XDEBUG_PORT}
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