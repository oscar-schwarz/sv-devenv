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

All configuration happens in the `devenv.nix` file. To get the correct development environment enable the module of the tech stack of your project. Then set the flavor to the correct project.

### Laravel Sail

```nix
sv.laravel-sail = {
  enable = true;
  flavor = "beste"; # or "plan" or "planer"
}
```

### Capacitor Ionic

```nix
sv.capacitor-ionic = {
  enable = true;
  flavor = "beste"; # or "plan"
}
```
