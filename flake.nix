{
  outputs = _: {
    devenvModule = {...}: {
      assertions = [
        {
          assertion = false;
          message = ''
            sv-devenv: do not import this repository as a flake.
            Use `flake: false` in devenv.yaml instead:

              inputs:
                sv-devenv:
                  url: github:oscar-schwarz/sv-devenv
                  flake: false
              imports:
              - sv-devenv
          '';
        }
      ];
    };
  };
}
