{ 
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.sv.vue-ionic;
in {
  options.sv.vue-ionic = {
    enable = mkEnableOption "development environment for a project using Vue with Ionic and Nuxt for bundling it";
  };
  config = mkIf cfg.enable {
    languages.javascript = {
      enable = true;
      npm.enable = true;
    };

    processes = {
      nuxt.exec = "npm run dev -- --port 3000 --debug";
    };
  };
}