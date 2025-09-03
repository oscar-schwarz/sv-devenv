{
  pkgs,
  lib,
  ...
}: let
  inherit (builtins) replaceStrings attrNames readDir;
  inherit (lib) pipe filterAttrs listToAttrs;
in {
  # add each nix file in ../lib directory as function
  config.lib = pipe ../lib [
    readDir
    (filterAttrs (_: value: value == "regular"))
    attrNames
    (map (replaceStrings [".nix"] [""]))
    (map (name: {
      inherit name;
      value = import "${../lib}/${name}.nix" pkgs;
    }))
    listToAttrs
  ];
}
