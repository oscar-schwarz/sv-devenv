{...}: let
  inherit (builtins) match;
in
  name: envFile: {
    assertion = (match "^[0-9]{4,}$" envFile.${name}) != null;
    message = ".env: ${name} (${envFile.${name}}) is either not a valid port or needs super user to be used. A valid port which can be accessed by normal users is a number between 1000 and 65535.";
  }
