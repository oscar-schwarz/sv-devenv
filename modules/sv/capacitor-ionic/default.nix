{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.sv.capacitor-ionic;
in {
  options.sv.capacitor-ionic = {
    enable = mkEnableOption "development environment for a project using Capacitor with Ionic and Vue";
    flavor = lib.mkOption {
      type = with lib.types; nullOr (enum ["beste" "plan"]);
      default = null;
      description = "The flavor of Capacitor Ionic configuration to use";
    };
    containerized = mkEnableOption "containerized `npm run dev`";
  };
  config = mkIf cfg.enable {
    packages = with pkgs; [
      podman
      podman-compose
    ];

    sv.extraWelcomeText =
      if cfg.flavor != null
      then "**Flavor:** `${cfg.flavor}`"
      else "";

    languages.javascript = {
      package = pkgs.nodejs_20;
      enable = true;
      npm.enable = true;
    };

    # Fix for javascript heap out of memory
    env = {
      NODE_OPTIONS = "--max-old-space-size=4096";
      CAPACITOR_ANDROID_STUDIO_PATH = lib.getExe config.android.android-studio.package;
    };

    processes =
      if cfg.containerized
      then {
        container = {
          exec = ''
              podman compose down
              podman compose up --build --detach
            :'';
          process-compose = {
            is_daemon = true;
            shutdown = {
              command = "podman compose down";
              timeout_seconds = 10;
            };
          };
        };
      }
      else {
        npm-run-dev.exec = "npm run dev -- --port 3000 --debug";
      };

    assertions = [
      {
        assertion = pkgs.config.allowUnfree;
        message = "`allowUnfree` is not enabled but for Android development unfree packages are needed. Set `allowUnfree: true` in your devenv.yaml";
      }
    ];

    android = {
      enable = true;
      platforms.version = ["34" "36"];
      systemImageTypes = ["google_apis_playstore"];
      abis = ["armeabi-v7a" "arm64-v8a"];
      cmake.version = ["3.18.1"];
      cmdLineTools.version = "11.0";
      tools.version = "26.1.1";
      platformTools.version = "36.0.0";
      buildTools.version = ["34.0.0"];
      emulator.enable = false;
      sources.enable = false;
      systemImages.enable = true;
      ndk.enable = true;
      googleAPIs.enable = true;
      # googleTVAddOns.enable = true;
      extras = ["extras;google;gcm"];
      # extraLicenses = [
      #   "android-sdk-preview-license"
      #   "android-googletv-license"
      #   "android-sdk-arm-dbt-license"
      #   "google-gdk-license"
      #   "intel-android-extra-license"
      #   "intel-android-sysimage-license"
      #   "mips-android-sysimage-license"
      # ];
      android-studio = {
        enable = true;
        # package = pkgs.android-studio;
      };
    };

    scripts.run-on-android-phone = {
      description = ''
        Builds the app with NodeJS and Gradle to a debug APK which is then installed on the connected Android device (must be available with `adb devices`)
      '';
      exec = ''
        applicationId=$(grep -oP 'applicationId\s+"\K[^"]+' android/app/build.gradle)

        npm run build --prod
        npx cap sync android
        cd android
        adb shell pm uninstall --user 0 $applicationId
        ./gradlew installDebug
        adb shell monkey -p $applicationId -c android.intent.category.LAUNCHER 1
      '';
    };
  };
}
