{
  ...
}: {
  dotenv.defaults = {
    FORWARD_DB_PORT = "\${DB_PORT}";
    VITE_PORT = "5173";
    APP_PORT = "80";
    XDEBUG_PORT = "9003";
    MAIL_UI_PORT = "2526";
  };
}