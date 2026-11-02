# sv-devenv

Development environments for various specific projects
## Installation

1. Install [devenv](https://devenv.sh/getting-started/) and initialize it in your project directory
```bash
devenv init
```

2. Add `sv-devenv` as an input

3. Then add the module into `devenv.yaml` to access all the options under [Configuration](#Configuration)
```yaml
inputs:
  sv-devenv:
    url: github:oscar-schwarz/sv-devenv
    flake: false
imports:
- sv-devenv
```

4. (Optional) Install [direnv](https://direnv.net/docs/installation.html) for automatic environment activation.

Then create a `.envrc` with the following content:

```envrc
eval "$(devenv direnvrc)"

use devenv
```

The devenv files are added to `.git/info/exclude` automatically, so they stay local.

## Configuration

All configuration happens in the `devenv.nix` file. To get the correct development environment enable the module of the tech stack of your project. Then set the flavor to the correct project.

### Laravel Sail

```nix
sv.laravel-sail = {
  enable = true;
  flavor = "<flavor>"; # one of the flavors in modules/sv/laravel-sail
}
```

On shell start, keys from `.env.example` that are missing in `.env` are counted, `env-check` lists them.

#### Octane and Xdebug

`sv.laravel-sail.octane.enable` (enabled by some flavors) writes a local `docker-compose.override.yml` that switches `laravel.test` to the FrankenPHP + Octane runtime from `sail/runtimes/frankenphp`. Rebuild with `sail build` after it changed.

- Workers reload on file changes (`--watch`), `octane-reload` forces it.
- The queue runs as the `queue-worker` process (`queue:listen`, queues `print`, `print-bulk`, `default`), so code changes apply without a restart.
- Printing works while Vite runs (flavors with a Gotenberg service): Chromium in Gotenberg resolves `localhost` to the app container, so the print pages load their assets from the Vite dev server.
- Xdebug is always on with `start_with_request=yes` and connects to port 9003 on the host. The project is mounted at `/app`, so map `/app` to the project directory in your IDE.
- Octane workers boot only once, so the `octaneXdebug` patch makes Octane's FrankenPHP worker call `xdebug_connect_to_client()` on every request. After `composer install`/`update` re-enter the shell to re-apply it and run `octane-reload`.

### App Wrapper

For native apps that wrap a web app in a WebView (Capacitor). Needs `allowUnfree: true` in `devenv.yaml`.

```nix
sv.app-wrapper = {
  enable = true;
  flavor = "<flavor>"; # one of the flavors in modules/sv/app-wrapper
}
```

- `emulator-start` creates the AVD on first use and starts the emulator.
- `app-run-local` builds the app, points the generated `capacitor.config.json` at `http://localhost:$APP_PORT` (optionally `LOCAL_CLIENT_ID`), forwards the ports with `adb reverse` and installs it on the emulator. `run-on-android-phone` does the same on a connected phone.
- Inspect the WebView at `chrome://inspect`.

## Patched Files

Some changes are convenient/needed for development but are not upstream. These can be applied as patches with the `patches.<name>` option (see `modules/patches.nix`), the diff files live in `diff/`.

Patching works as follows. A diff file is applied to a file when the devshell is started and in a post-commit and post-checkout git hook.
If a patched file is tracked by git it will be updated with `git update-index --assume-unchanged path/to/file` before the patch so that the patch does not appear in `git status`.


### Updating a Patched File

In the rare case where you want to make changes to a patched file.

1. `git update-index --no-assume-unchanged path/to/file`
2. `git add path/to/file && git stash` (remove the patch from the file)
3. Make your changes and commit
4. After the commit the patch will be tried to be applied again
  - If the patch was not applied proceed to [A Patched File was updated Upstream](#a-patched-file-was-updated-upstream)


### A Patched File was updated Upstream

If you see `Could not apply <name> patch, is the diff out-of-date?` during shell init, the diff file of that patch needs to be updated.
