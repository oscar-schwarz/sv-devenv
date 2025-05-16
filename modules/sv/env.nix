{ lib, config, ... }: let 
  inherit (builtins) attrNames replaceStrings attrValues elem filter match head;
  inherit (lib) mkIf pipe mkOption attrsToList types concatLines removeSuffix mapAttrs;

  cfgLib = config.lib.sv;
in {
  options.dotenv = {
    defaults = mkOption {
      description = ''
        The default values for certain values that are not found in the .env file.
      '';
      type = with types; attrsOf str;
      default = {};
    };
  };

  config = mkIf cfgLib.enable {
    dotenv.enable = true;

    # Post process values from .env
    env = pipe config.dotenv.resolved [
      # add the defaults
      (set: config.dotenv.defaults // set)

      # strip away comments at the end and quotation marks
      (mapAttrs (_: value: 
        pipe value [
          (match "([^#]*)#.*") # find valid part of value
          
          (groups: if groups == null then value else head groups) # get valid part from matches

          # remove quotation marks
          (replaceStrings ["\""] [""])

          # dumb way of remove trailing spaces
          (removeSuffix " ")
          (removeSuffix "  ")
          (removeSuffix "   ")
        ]
      ))

      # Now we need to substitute any variables (in dotenv you can reference another variable with ${VAR})
      (set: mapAttrs (name: value: 
        replaceStrings
          (map (name: "\${${name}}") (attrNames set))
          (attrValues set)
          value
      ) set)
    ];

    enterShell = 
    # We need to unset the variables as the env variables being defined in the shell breaks some things 
     (pipe config.dotenv.resolved [
        attrNames # only names
        (map (e: "unset ${e}")) # add command to unset each env var
        concatLines # concat to string
      ])
    # insert varaibles into .env which have defaults defined
    + (pipe config.dotenv.defaults) [
      attrsToList
      (filter (e: !(elem e.name (attrNames config.dotenv.resolved)))) # filter by not in env
      # map to commands
      (map (e: ''
        echo -e '\n${e.name}=${e.value}\n' >> .env
        echo "${e.name} not found in .env file. Adding it with a default value. (${e.value})"
      ''))
      # concat
      concatLines
    ];
  };
}