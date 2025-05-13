{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkOption types;
  
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
        default = "dockerd-rootless";
        type = types.str;
      };
    };
    enableHMRPatch = mkEnableOption "the patch that fixes Vite HMR in the container";
    enableXDebugPatch = mkEnableOption "the patch that fixes XDebug inside the container";
  };
 
  config = mkIf cfg.enable {
    packages = with pkgs; [
      podman-compose
    ] ++ (if cfg.dockerd.enable then [
      docker
    ] else []);

    # Shell hook things specific to container mode of web
    enterShell = ''
      # --- Add scripts from vendor/bin to path
      export PATH="$PATH:$DEVENV_ROOT/vendor/bin"

      # --- Warning to fix permissions in laravel storage
      if [[ "$(stat -c "%a" $DEVENV_ROOT)" != "777" ]]; then
        echo -e '
        ## Warning
        
        The repository directory does not have the 777 permission, without it the sail user in the container cannot write to it. Sudo is required to add it.
        Change the permissions with:

        `sudo chmod -R 777 .`
        ' | ${lib.getExe pkgs.glow}
      fi
    ''
    + (if cfg.dockerd.enable then ''
        # --- dockerd needs that to function properly
        export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
        export DOCKERD_ROOTLESS_ROOTLESSKIT_DISABLE_HOST_LOOPBACK=false
    '' else "")
    + (if cfg.enableHMRPatch then ''
      patch --forward -r - < ${../../../diff/hmr-fix.diff}
      git update-index --assume-unchanged vite.config.js
    '' else "")
    + (if cfg.enableXDebugPatch then ''
      phpIni=vendor/laravel/sail/runtimes/8.3/php.ini
      if ! grep -q "start_with_request=yes" $phpIni; then
        echo -e "\\n[xdebug]\\nxdebug.start_with_request=yes" >> $phpIni
        devenv up --detach
        sail build --quiet
        devenv processes stop
      fi
    '' else "");
  };
}