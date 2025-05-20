{
  lib,
  ...
}: let 
  inherit (builtins) head replaceStrings attrNames foldl';
  inherit (lib) pipe; 

  recursivelyFindOptionAndPath = option: path:
    if (option ? "__module") then
      foldl' (acc: elem: 
        acc ++ (recursivelyFindOptionAndPath option.${elem} "path.${elem}")
      ) {} (attrNames option)
    else
      [{name = path; value = option;}];

  optionToMD = {option, path}: let 
    line = (head option.declarationPositions).line;
    file = replaceStrings ["${../.}"] [""] (head option.declarationPositions).file;
  in ''
  ## [${path}](${file}#L${line})
  '';
in
options: pipe options [
  recursivelyFindOptionAndPath
]