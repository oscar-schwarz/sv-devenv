{ 
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.sv.vue-ionic;
in {
  options.sv.vue-ionic = {
    enable = mkEnableOption "development environment for a project using Vue with Ionic and Nuxt for bundling it";
  };
  config = mkIf cfg.enable {
    languages.javascript = {
      package = pkgs.nodejs_20;
      enable = true;
      npm.enable = true;
    };

    processes = {
      nuxt.exec = "npm run dev -- --port 3000 --debug";
    };

    assertions = [{
      assertion = pkgs.config.allowUnfree;
      message = "`allowUnfree` is not enabled but for Android development unfree packages are needed. Set `allowUnfree: true` in your devenv.yaml";
    }];

    android = {
      enable = true;
      platforms.version = [ "28" "29" "30" "34" ];
      systemImageTypes = [ "google_apis_playstore" ];
      abis = [ "armeabi-v7a" "arm64-v8a" ];
      cmake.version = [ "3.18.1" ];
      cmdLineTools.version = "11.0";
      tools.version = "26.1.1";
      platformTools.version = "34.0.1";
      buildTools.version = [ "34.0.0" ];
      emulator.enable = false;
      sources.enable = false;
      systemImages.enable = true;
      ndk.enable = true;
      googleAPIs.enable = true;
      googleTVAddOns.enable = true;
      extras = [ "extras;google;gcm" ];
      extraLicenses = [
        "android-sdk-preview-license"
        "android-googletv-license"
        "android-sdk-arm-dbt-license"
        "google-gdk-license"
        "intel-android-extra-license"
        "intel-android-sysimage-license"
        "mips-android-sysimage-license"
      ];
      android-studio = {
        enable = true;
        package = pkgs.android-studio;
      };
    };

    scripts.build-apk.exec = ''
      applicationId=$(grep -oP 'applicationId\s+"\K[^"]+' android/app/build.gradle)

      npm run build --prod
      npx cap sync android
      cd android
      adb shell pm uninstall --user 0 $applicationId
      ./gradlew installDebug
      adb shell monkey -p $applicationId -c android.intent.category.LAUNCHER 1 
    '';
  };
}