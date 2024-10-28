{
  description = "A very simple Nix flake that loads `devenv` into path when opening the devshell.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        {
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [ devenv curl ];

            # Fetch the devenv.nix files if not present in repo
            shellHook = ''
              if ! [ -f "devenv.nix" ]; then
                curl https://raw.githubusercontent.com/oscar-schwarz/devenv-beste-schule/refs/heads/main/devenv.lock \
                  > devenv.lock && \
                curl https://raw.githubusercontent.com/oscar-schwarz/devenv-beste-schule/refs/heads/main/devenv.nix \
                  > devenv.nix && \
                curl https://raw.githubusercontent.com/oscar-schwarz/devenv-beste-schule/refs/heads/main/devenv.yaml \
                  > devenv.yaml
              fi
            '';
          };
        }
      );
}
