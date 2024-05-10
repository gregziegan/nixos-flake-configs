{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.red-door-collective.rdc-website;
in
{
  options.services.red-door-collective.rdc-website = {
    enable = mkEnableOption "Starts court data site";

    port = mkOption {
      type = types.port;
      default = 8080;
      example = 9001;
      description = "The port number the RDC website should listen on for HTTP traffic";
    };

    domain = mkOption {
      type = types.str;
      default = "reddoorcollective.online";
      example = "reddoorcollective.online";
      description =
        "The domain name that nginx should check against for HTTP hostnames";
    };
  };

  config = lib.mkIf cfg.enable {

    users.users.red-door-collective = {
      createHome = true;
      description = "github.com/red-door-collective/rdc-website";
      isSystemUser = true;
      group = "red-door-collective";
      home = "/srv/red-door-collective/rdc-website";
      extraGroups = [ "keys" ];
    };

    red-door-collective.secrets.rdc-website = {
      source = ./secrets/red-door-collective/rdc-website.env;
      dest = "/srv/red-door-collective/rdc-website/.env";
      owner = "red-door-collective";
      group = "red-door-collective";
      permissions = "0400";
    };

    red-door-collective.secrets.rdc-website-google-service-account = {
      source = ./secrets/google_service_account.json;
      dest = "/srv/red-door-collective/rdc-website/google_service_account.json";
      owner = "red-door-collective";
      group = "red-door-collective";
      permissions = "0400";
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    systemd.services.red-door-collective.rdc-website = {
      description = "A webapp that presents and verifies court data";

      wantedBy = [ "multi-user.target" ];
      after = [ "rdc-website-key.service" "postgresql.service" ];
      wants = [ "rdc-website-key.service" "postgresql.service" ];

      serviceConfig = {
        User = "red-door-collective";
        Group = "red-door-collective";
        Restart = "on-failure";
        WorkingDirectory = "/srv/red-door-collective/rdc-website";
        RestartSec = "30s";

        #  # Security
        # CapabilityBoundingSet = "";
        # DeviceAllow = [ ];
        # NoNewPrivileges = "true";
        # ProtectControlGroups = "true";
        # ProtectClock = "true";
        # PrivateDevices = "true";
        # PrivateUsers = "true";
        # ProtectHome = "true";
        # ProtectHostname = "true";
        # ProtectKernelLogs = "true";
        # ProtectKernelModules = "true";
        # ProtectKernelTunables = "true";
        # ProtectSystem = "true";
        # ProtectProc = "invisible";
        # RemoveIPC = "true";
        # RestrictSUIDSGID = "true";
        # RestrictRealtime = "true";
        # SystemCallArchitectures = "native";
        # SystemCallFilter = [
        # "~@reboot"
        # "~@module"
        # "~@mount"
        # "~@swap"
        # "~@resources"
        # "~@cpu-emulation"
        # "~@obsolete"
        # "~@debug"
        # "~@privileged"
        # ];
        # UMask = "077";
      };

      script =
        let site = pkgs.github.com.red-door-collective.rdc-website;
        in ''
          export $(cat /srv/red-door-collective/rdc-website/.env | xargs)
          export FLASK_APP="rdc_website.app"
          ${site}/bin/migrate
          export FLASK_APP="rdc_website"
          ${site}/bin/run
        '';
    };
  };
}
