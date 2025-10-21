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

## Patched Files

Some changes are patches are convenient/needed for development but are not yet upstream. These patches include for example the `jsconfig` patch which fixes the `jsconfig.json` so that the typescript language server works correctly.
The files which get patches are usually be configuration files as these are configured once and then not updated in a long time.

Patching works as follows. In the `diff/` directory of this repository there are diff files which will be applied to certain files when the devshell is started and in a post-commit and post-checkout git hook.
If a patched file is tracked by git it will be updated with `git update-index --assume-unchanged path/to/file` before the patch so that the patch does not appear in `git status`.


### Updating a Patched File

In the rare case where you want to make changes to a patched file.

1. `git update-index --no-assume-unchanged path/to/file`
2. `git add path/to/file && git stash` (remove the patch from the file)
3. Make your changes and commit
4. After the commit the patch will be tried to be applied again
  - If the patch was not applied proceed to [A Patched File was updated Upstream](#a-patched-file-was-updated-upstream)


### A Patched File was updated Upstream

If you see `Could not apply <name> patch, is the diff out-of-date?` during shell init notify me or try to fix the associated diff file yourself.
To find out which diff file is affected look at `sv/default.nix` in this repository and look in the `patches` block for the patch name.
