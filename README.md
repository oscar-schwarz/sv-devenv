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
{ inputs, ... }:
  imports = [ inputs.sv-devenv.outputs.devenvModule ];
}
```

4. (Optional) Install [direnv](https://direnv.net/docs/installation.html) for automatic environment activation.

Then create a `.envrc` with the following content:

```envrc
eval "$(devenv direnvrc)"

use devenv
```

## Configuration

To get started with the vite-vue-laravel repository with sail enabled put this into your `devenv.nix`:

```nix
sv.vite-vue-laravel = {
  enable = true;
  sail.enable = true;
}
```

### Options

#### `sv.vite-vue-laravel.enable`
- **Type**: boolean
- **Default**: `false`
- **Description**: Enables the development environment for a project using Vue for a JS frontend, Vite for bundling it and Laravel as a backend.

#### `sv.vite-vue-laravel.sail.enable`
- **Type**: boolean
- **Default**: `false`
- **Description**: Enables the containerized version of Laravel using Laravel Sail.

#### `sv.vite-vue-laravel.sail.dockerd.enable`
- **Type**: boolean
- **Default**: `false`
- **Description**: Enables the docker daemon running as a process. Removes the need to have a container engine running.

#### `sv.vite-vue-laravel.sail.dockerd.ready_log_line`
- **Type**: string
- **Default**: `"Daemon has completed initialization"`
- **Description**: The docker daemon is considered initialized when the log contains this string.

#### `sv.vite-vue-laravel.sail.dockerd.exec`
- **Type**: string
- **Default**: `"dockerd-rootless --host $DOCKER_HOST"`
- **Description**: The command to run the docker daemon.

#### `sv.vite-vue-laravel.sail.enableHMRPatch`
- **Type**: boolean
- **Default**: `false`
- **Description**: Enables the patch that fixes Vite Hot Module Replacement (HMR) in the container.

#### `sv.vite-vue-laravel.sail.enableXDebugPatch`
- **Type**: boolean
- **Default**: `false`
- **Description**: Enables the patch that fixes XDebug inside the container.

#### `sv.vue-ionic.enable`
- **Type**: boolean
- **Default**: `false`
- **Description**: Enables the development environment for a project using Vue with Ionic and Nuxt for bundling it.
