{
  lib,
  ...
}: let 
  inherit (builtins) filter match listToAttrs head replaceStrings;
  inherit (lib) pipe splitString last removeSuffix;

  keyValueRegex = ''^([A-Za-z_]+=[^#]+).*'';
in
filepath: pipe filepath [
  # split to each line
  (splitString "\n")

  # filter out valid VARIABLE=VALUE or VARIABLE="http://example.com"
  (filter (line: match keyValueRegex line != null))

  # map key values correctly
  (map (line: let 
    keyValuePair = pipe line [
      # match only the key=value part
      (match keyValueRegex)
      # take the result of the first match group
      head
      # split to key and value
      (splitString "=")
    ];
  in {
    name = head keyValuePair;
    value = pipe keyValuePair [
      last # take value
      (replaceStrings ["\""] [""]) # remove "
      # dumb way of remove trailing spaces
      (removeSuffix " ")
      (removeSuffix "  ")
      (removeSuffix "   ")
    ];  
  }))

  # Now we need to substitute any variables (in dotenv you can reference another variable with ${VAR})
  (list: map ({name, value}: {
    inherit name;
    value = replaceStrings
      (map (e: "\${${e.name}}") list)
      (map (e: e.value) list)
      value;
  }) list)

  # to set
  listToAttrs
]