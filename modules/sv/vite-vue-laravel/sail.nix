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
        default = "API listen on";
        type = types.str;
      };
      exec = mkOption {
        description = "The command to run the daemon.";
        default = "dockerd-rootless";
        type = types.str;
      };
    };
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
    '' else "");

    processes = {
      
    };
  };
}