# beste.schule development enviroment using devenv

## Usage

`devenv shell` (or automatically with direnv)

## Installation

1. install [devenv](https://devenv.sh)

2. Fetch the files from this repo into the beste.schule repo. For example, like this:
  ```bash
cd <path to the repo here>
curl -O https://github.com/oscar-schwarz/devenv-beste-schule/archive/refs/heads/without-readme.zip
unzip without-readme.zip
rm without-readme.zip
  ```

3. (optional if you're using direnv) Put this in your `.envrc`
  ```bash
    source_url "https://raw.githubusercontent.com/cachix/devenv/82c0147677e510b247d8b9165c54f73d32dfd899/direnvrc" "sha256-7u4iDd1nZpxL4tCzmPG0dQgC5V+/44Ba+tHkPob1v2k="

    use devenv
  ```

