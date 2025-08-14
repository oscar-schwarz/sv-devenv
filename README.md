# sv-devenv

Development environments for various specific projects
## Installation

1. Install [devenv](https://devenv.sh/getting-started/)

2. Run the following commands to initialize devenv and to add this repository:
```
devenv init
devenv inputs add sv-devenv github:oscar-schwarz/sv-devenv 
```

3. Then import the module inside of the `devenv.nix` to access all the options under [Configuration](#Configuration)
```nix
{ inputs, ... }: {
  imports = [ inputs.sv-devenv.devenvModule ];
}
```

4. (Optional) Install [direnv](https://direnv.net/docs/installation.html) for automatic environment activation.

Then create a `.envrc` with the following content:

```envrc
eval "$(devenv direnvrc)"

use devenv
```

## Configuration

To get started with the laravel-sail repository put this into your `devenv.nix`:

```nix
sv.laravel-sail = {
  enable = true;
}
```
