{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;

  cfg = config.sv.laravel-sail;
in {
  config = mkIf (cfg.enable && cfg.flavor == "beste") {
    sv.laravel-sail.nodejs-frontend.enable = true;
    sv.laravel-sail.octane.enable = true;

    # While Vite runs, print pages load their assets from http://localhost:5173 (public/hot).
    # Chromium in Gotenberg resolves localhost to the app container, where Vite listens, so printing works with hot reload.
    sv.laravel-sail.composeOverride.services.gotenberg.command = [
      "gotenberg"
      "--api-timeout=120s"
      "--chromium-allow-list=^http://laravel\\.test/(print/render/.*|build/.*)$$"
      "--chromium-allow-list=^(http|ws)://localhost:${config.envFile.VITE_PORT or "5173"}/.*$$"
      "--chromium-host-resolver-rules=MAP localhost laravel.test"
    ];

    # Enable check-types-ts git hook
    git-hooks.hooks.check-types-ts = {
      enable = true;
      name = "check-types-ts";
      description = "does some validation on types.ts, like type sorting order";
      files = "^resources/js/types\.ts$";
      entry = lib.getExe (pkgs.writeShellApplication {
        name = "check-types-ts";
        runtimeInputs = [pkgs.ripgrep pkgs.coreutils];
        text = ''
          rg '^export (type|interface) (\w+)' --only-matching --replace '$2' --no-filename "$@" | sort --check
        '';
      });
    };
  };
}
