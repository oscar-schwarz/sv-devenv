# NixOS Module Options


## [`options.dotenv.defaults`](modules/sv/env.nix#L9)


The default values for certain values that are not found in the .env file.


**Type:** `with types; attrsOf str`

**Default:** `{}`

## [`options.envFile`](modules/sv/env.nix#L18)


Devenv does not parse .env files correctly. We also need to substitute variables and remove comments. This is done here.


**Type:** `options.env.type`

**Default:** `{}`

## [`options.sv.vue-ionic.enable`](modules/sv/vue-ionic/default.nix#L12)

development environment for a project using Vue with Ionic and Nuxt for bundling it

**Type:** `boolean`

**Default:** `false`

**Example:** `true`

## [`options.sv.vite-vue-laravel.sail.enable`](modules/sv/vite-vue-laravel/sail.nix#L14)

the containerized version of Laravel

**Type:** `boolean`

**Default:** `false`

**Example:** `true`

## [`options.sv.vite-vue-laravel.sail.dockerd.enable`](modules/sv/vite-vue-laravel/sail.nix#L16)

docker daemon running as a process. Removes to the need to having a container engine running.

**Type:** `boolean`

**Default:** `false`

**Example:** `true`

## [`options.sv.vite-vue-laravel.sail.dockerd.ready_log_line`](modules/sv/vite-vue-laravel/sail.nix#L17)

The docker daemon is considered initialized when the log contains this string.

**Type:** `types.str`

**Default:** `"Daemon has completed initialization"`

## [`options.sv.vite-vue-laravel.sail.dockerd.exec`](modules/sv/vite-vue-laravel/sail.nix#L22)

The command to run the daemon.

**Type:** `types.str`

**Default:** `"dockerd-rootless --host $DOCKER_HOST"`

## [`options.sv.vite-vue-laravel.sail.enableHMRPatch`](modules/sv/vite-vue-laravel/sail.nix#L28)

the patch that fixes Vite HMR in the container

**Type:** `boolean`

**Default:** `false`

**Example:** `true`

## [`options.sv.vite-vue-laravel.sail.enableXDebugPatch`](modules/sv/vite-vue-laravel/sail.nix#L29)

the patch that fixes XDebug inside the container

**Type:** `boolean`

**Default:** `false`

**Example:** `true`

## [`options.sv.vite-vue-laravel.enable`](modules/sv/vite-vue-laravel/default.nix#L13)

development environment for a project using Vue for a JS frontend, Vite for bundling it and Laravel as a backend

**Type:** `boolean`

**Default:** `false`

**Example:** `true`

## [`options.assertionWarnings`](modules/assertionWarnings.nix#L10)

Like `assertions` but for warnings

**Type:** `options.assertions.type`

**Default:** `[]`

---
*Generated with [nix-options-doc](https://github.com/Thunderbottom/nix-options-doc)*
