{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
  ];

  environment.systemPackages = [
    config.services.postgresql.package
  ];

  services.nginx = with config.settings; {
    virtualHosts = {
      "reddoorcollective.org" = {
        default = true;
        locations."/api/" = {
          proxyPass = "http://127.0.0.1:10000";
        };

        locations."/" = {
          alias = "${config.services.red-door-collective.rdc-website.staticFiles}/";
        };

        addSSL = true;
        enableACME = true;
      };
    };
  };

  services.red-door-collective.rdc-website = with config.settings; {
    enable = true;
    secretFiles = {
      flask_secret_key = "/var/lib/rdc-website/flask-secret-key";
      password_salt = "/var/lib/rdc-website/password-salt";
      database_uri = "/var/lib/rdc-website/database-uri";
      cloudinary_api_key = "/var/lib/rdc-website/cloudinary-api-key";
      cloudinary_secret = "/var/lib/rdc-website/cloudinary-secret";
      twilio_account_sid = "/var/lib/rdc-website/twilio-account-sid";
      twilio_auth_token = "/var/lib/rdc-website/twilio-auth-token";
      mail_admin = "/var/lib/rdc-website/mail-admin";
      mail_server = "/var/lib/rdc-website/mail-server";
      mail_port = "/var/lib/rdc-website/mail-port";
      mail_username = "/var/lib/rdc-website/mail-username";
      mail_password = "/var/lib/rdc-website/mail-password";
      rollbar_client_token = "/var/lib/rdc-website/rollbar-client-token";
      caselink_username = "/var/lib/rdc-website/caselink-username";
      caselink_password = "/var/lib/rdc-website/caselink-password";
    };

    extraConfig = {
      SECRET_KEY = "@flask_secret_key@";
      SECURITY_PASSWORD_SALT = "@password_salt@";
      SQLALCHEMY_DATABASE_URI = "@database_uri@";
      GOOGLE_SERVICE_ACCOUNT = "/var/lib/rdc-website/google-service-account";
      CLOUDINARY_API_KEY = "@cloudinary_api_key@";
      CLOUDINARY_SECRET = "@cloudinary_secret@";
      TWILIO_ACCOUNT_SID = "@twilio_account_sid@";
      TWILIO_AUTH_TOKEN = "@twilio_auth_token@";
      MAIL_ADMIN = "@mail_admin@";
      MAIL_SERVER = "@mail_server@";
      MAIL_PORT = "@mail_port@";
      MAIL_USERNAME = "@mail_username@";
      MAIL_PASSWORD = "@mail_password@";
      ROLLBAR_CLIENT_TOKEN = "@rollbar_client_token@";
      CASELINK_USERNAME = "@caselink_username@";
      CASELINK_PASSWORD = "@caselink_password@";

      DATA_DIR = "./data";
      DEBUG = false;
      ENV = "production";
      FLASK_APP = "rdc_website.app";
      FLASK_DEBUG = false;
      MAIL_DEBUG = false;
      MAIL_USE_SSL = false;
      MAIL_USE_TLS = true;
      RUN_JOBS = false;
      SECURITY_AUTO_LOGIN_AFTER_CONFIRM = false;
      SECURITY_CHANGEABLE = true;
      SECURITY_CONFIRMABLE = true;
      SECURITY_CONFIRM_ERROR_VIEW = "/confirm-error";
      SECURITY_CSRF_COOKIE = {key = "XSRF-TOKEN";};
      # SECURITY_CSRF_COOKIE_NAME = "XSRF-TOKEN";
      SECURITY_CSRF_IGNORE_UNAUTH_ENDPOINTS = true;
      SECURITY_CSRF_PROTECT_MECHANISMS = ["session" "basic"];
      SECURITY_FLASH_MESSAGES = false;
      SECURITY_POST_CONFIRM_VIEW = "/confirmed";
      SECURITY_RECOVERABLE = true;
      SECURITY_REDIRECT_BEHAVIOR = "spa";
      SECURITY_REDIRECT_HOST = "reddoorcollective.org";
      SECURITY_RESET_ERROR_VIEW = "/reset-password";
      SECURITY_RESET_VIEW = "/reset-password";
      SECURITY_TRACKABLE = true;
      SECURITY_URL_PREFIX = "/api/v1/accounts";
      SQLALCHEMY_TRACK_MODIFICATIONS = false;
      VERSION = "testing-deploy";
      SQLALCHEMY_ENGINE_OPTIONS = {
        pool_pre_ping = true;
      };
      WTF_CSRF_CHECK_DEFAULT = false;
      WTF_CSRF_TIME_LIMIT = null;
    };
  };

  # systemd.services.rdc-website-db = {
  #   requires = ["postgresql.service"];
  #   after = ["postgresql.service"];
  #   path = [config.services.postgresql.package];
  #   script = ''
  #     psql -c 'CREATE USER rdc_website' || true
  #     psql -c 'CREATE DATABASE rdc_website WITH OWNER rdc_website' || true
  #     psql -c 'GRANT ALL ON DATABASE rdc_website TO rdc_website'
  #   '';

  #   serviceConfig = {
  #     User = "postgres";
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #   };
  # };
}
