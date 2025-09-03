{
  lib,
  config,
  options,
  ...
}: let
  inherit (builtins) filter;
  inherit (lib) mkOption pipe;
in {
  options.assertionWarnings = mkOption {
    description = "Like `assertions` but for warnings";
    type = options.assertions.type;
    default = [];
  };
  config.warnings = pipe config.assertionWarnings [
    (filter (e: !e.assertion)) # filter out failed assertions
    (map (e: e.message)) # only message
  ];
}
