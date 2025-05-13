# beste.schule development enviroment using devenv

## Usage

`devenv shell` (or automatically with direnv)

## (recommended) Installation with direnv

1. Put this in your `.envrc`
```bash
# make devenv available in shell and download beste.schule devenv files
use flake github:oscar-schwarz/devenv-beste-schule/4280a5abff530d81abc09e1be6204e0da8ebdf28

# `devenv shell` on direnv trigger
source_url "https://raw.githubusercontent.com/cachix/devenv/82c0147677e510b247d8b9165c54f73d32dfd899/direnvrc" "sha256-7u4iDd1nZpxL4tCzmPG0dQgC5V+/44Ba+tHkPob1v2k="
use devenv
```

2. `direnv allow`

## Installation

1. install [devenv](https://devenv.sh)

2. Fetch the files from this repo into the beste.schule repo. For example, like this:
  ```bash
curl https://raw.githubusercontent.com/oscar-schwarz/devenv-beste-schule/refs/heads/main/devenv.lock \
  > devenv.lock && \
curl https://raw.githubusercontent.com/oscar-schwarz/devenv-beste-schule/refs/heads/main/devenv.nix \
  > devenv.nix && \
curl https://raw.githubusercontent.com/oscar-schwarz/devenv-beste-schule/refs/heads/main/devenv.yaml \
  > devenv.yaml
  ```
3. launch the shell with `devenv up`

