{
  pkgs,
  lib,
  ...
}: let
  inherit (builtins) replaceStrings attrNames readDir;
  inherit (lib) pipe filterAttrs listToAttrs;
in {
  imports = [
    ./patches.nix
    ./dotenv.nix

    ./sv
    ./sv/app-wrapper
    ./sv/app-wrapper/beste.nix
    ./sv/laravel-sail
    ./sv/laravel-sail/beste.nix
    ./sv/laravel-sail/planer.nix
    ./sv/laravel-sail/plan.nix
  ];

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
