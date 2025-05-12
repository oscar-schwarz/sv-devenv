{ lib, config, ... }: let 
  inherit (lib) mkEnableOption mkOption types mkIf;
  
  cfg = config.beste-schule;
in {
  options = {
    beste-schule = {
      enable = mkEnableOption "beste-schule module";
      repo = mkOption {
        description = ''
          For which repository the devenv shell is used.
        '';
        type = types.enum [ "web" "app" "plan.schule" ];
      };
      mode = mkOption {
        description = ''
          Which way the beste-schule instance is set up. Either dockerized or running natively.
        '';
        type = types.enum [ "container" "native" ];
        default = "native";
      };
      dockerDaemonProcess = mkEnableOption ''
        a docker-rootless daemon as a process. Has only an effect in mode "container". 
        Removes the need to have container engine running on the system.
      '';
    };
  };

  config =  {
    # Disable the cachix cache by default
    cachix.enable = mkIf cfg.enable (lib.mkDefault false);

    # Some utility functions
    config.lib.beste-schule = {
      isWeb = cfg.enable && cfg.repo == "web";
      isApp = cfg.enable && cfg.repo == "app";
      isNative = cfg.enable && cfg.mode == "native";
      isContainer = cfg.enable && cfg.mode == "container";
    };
  };
}