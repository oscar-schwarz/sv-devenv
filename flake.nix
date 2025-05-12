{
  description = "The flake for the beste schule devenv";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    devenv.url = "github:cachix/devenv";
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
  };
  outputs = { nixpkgs, flake-utils, devenv, ... }: let 
    pkgs = import nixpkgs {};
  in rec {
    devenvModule = { lib, ... }: {
      imports = lib.filesystem.listFilesRecursive ./modules;
    };
    project = pkgs.lib.evalModules {
      specialArgs = {
        inherit pkgs;
        inputs = devenv.inputs;
      };
      modules = [
        devenvModule
        "${devenv.outPath}/src/modules/top-level.nix"
      ];
    };
  }
  // ( flake-utils.lib.eachDefaultSystem
    (system: let 
      pkgs = import devenv.inputs.nixpkgs {inherit system;};
    in {
      devShells.default = pkgs.mkShell {
        shellHook = ''
          nix repl --expr "(builtins.getFlake \"$PWD\").outputs.project"
        '';
      };
    })
  );
}
