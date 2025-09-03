{
  lib,
  config,
  ...
}:
lib.mkIf config.sv.laravel-sail.enable {
  dotenv.defaults = {
    FORWARD_DB_PORT = "\${DB_PORT}";
    APP_PORT = "80";
  };
}
