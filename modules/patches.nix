{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types mkIf pipe concatStringsSep mapAttrsToList filterAttrs;

  cfg = config.patches;

  patchSubmodule = types.submodule {
    options = {
      enable = mkEnableOption "this patch";

      diffFile = mkOption {
        type = types.path;
        description = "Path to the diff/patch file";
      };

      patchedFile = {
        localPath = mkOption {
          type = types.str;
          description = "Local path to the file that will be patched";
        };

        isTracked = mkOption {
          type = types.bool;
          default = true;
          description = "Whether the patched file is tracked by git";
        };
      };
    };
  };

  # Generate patch commands using pipe
  patchCommands = pipe cfg [
    (filterAttrs (_: patch: patch.enable))
    (mapAttrsToList (name: patch:
      ''
        patch --forward --no-backup-if-mismatch -r - ${patch.patchedFile.localPath} < ${patch.diffFile}
      ''
      + (
        if patch.patchedFile.isTracked
        then ''
          git update-index --assume-unchanged ${patch.patchedFile.localPath}
        ''
        else ""
      )))
    (concatStringsSep "\n")
    # allow errors
    (str: ''
      set +e
      ${str}
      set -e
    '')
  ];
in {
  options.patches = mkOption {
    type = types.attrsOf patchSubmodule;
    default = {};
    description = "Configuration for patches to apply";
  };

  config = mkIf (patchCommands != "") {
    enterShell = patchCommands;
    lib = {inherit patchCommands;};

    # We need to add commit hooks that apply our patches as commiting or checkout reverses the --assume-unchanged
    git-hooks.hooks.apply-patches = {
      enable = true;
      entry = toString (pkgs.writeShellScript "apply-patches" patchCommands);
      stages = ["post-checkout" "post-commit"];
      always_run = true;
      description = "Apply patches after git checkout and commit";
    };
  };
}
