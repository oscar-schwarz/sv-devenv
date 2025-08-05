{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (builtins) concatStringsSep;
  inherit (lib) mkIf mkEnableOption mkOption types pipe;
  boolStr = bool: if bool then "true" else "false";

  cfg = config.sv.vite-vue-laravel.sail;
in {
  options.sv.vite-vue-laravel.sail = {
    enable = mkEnableOption "the containerized version of Laravel";
    dockerd = {
      enable = mkEnableOption "docker daemon running as a process. Removes to the need to having a container engine running.";
      ready_log_line = mkOption {
        description = "The docker daemon is considered initialized when the log contains this string.";
        default = "Daemon has completed initialization";
        type = types.str;
      };
      exec = mkOption {
        description = "The command to run the daemon.";
        default = "dockerd-rootless --host $DOCKER_HOST";
        type = types.str;
      };
    };
    enableXDebugPatch = mkEnableOption "the patch that fixes XDebug inside the container";
  };
 
  config = mkIf cfg.enable {
    packages = with pkgs; [
      podman-compose
    ] ++ (if cfg.dockerd.enable then [
      docker
    ] else []);

    env = mkIf cfg.dockerd.enable {
      DOCKER_HOST = "unix://${config.env.DEVENV_STATE}/dockerd.sock";
      DOCKERD_ROOTLESS_ROOTLESSKIT_DISABLE_HOST_LOOPBACK = "false";
    };

    # Shell hook things specific to container mode of web
    enterShell = ''
      # --- Add scripts from vendor/bin to path
      export PATH="$PATH:$DEVENV_ROOT/vendor/bin"

      # --- Warning to fix permissions in laravel storage
      if [[ ${
        pipe ["package-lock.json" "package.json" "storage" "node_modules" "vendor"] [
          (map (file: ''"$(stat -c "%a" ${file})" != 777''))
          (concatStringsSep " || ")
        ]
      } ]]; then
        echo -e '
        ## Warning
        
        The repository directory does not have the 777 permission, without it the sail user in the container cannot write to it. Sudo is required to add it.
        Change the permissions with:

        `sudo chmod -R 777 .`
        ' | ${lib.getExe pkgs.glow}
      fi
    ''
    + (if cfg.enableXDebugPatch then ''
      echo '> Applying XDebug Patch...'
      patch --forward -r - --batch vendor/laravel/sail/runtimes/8.3/php.ini < ${../../../diff/xdebug-fix.diff}
      # index doesnt need to be update as vendor file is not tracked 
    '' else "");
  };
}