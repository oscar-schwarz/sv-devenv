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

## Troubleshooting

### Making changes to patched files

In certain modules some files will be patched and to keep the working tree diff clean their index is updated in git with `git update-index --assume-unchanged path/to/file`.
So when you are trying to make changes to these files git will not notice these changes. Work around that as follows:

1. `git update-index --no-assume-unchanged path/to/file` - make changes to git visible

2. `git restore path/to/file` - remove patched changes

3. (make your changes and commit)

4. After committing the patch will tried to be applied again.
  The patch might fail due to changed context. You can temporarily disable the patch with `patches.<name>.enable = lib.mkForce false`.
  To find the `name` run `devenv repl` and in there `devenv.patches` and look for the patch that patches the updated file in `patchFile.localPath`
