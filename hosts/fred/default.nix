{
  pkgs,
  config,
  inputs,
  ...
}: let
  hostName = "fred";
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    inputs.rdc-website.nixosModules.default
    ../../common/services/rdc-website.nix
    ../../common/services/observability
  ];

  # Bootloader.
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };

      efi.canTouchEfiVariables = true;
    };
  };

  networking.hostName = hostName;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
    };
    openFirewall = true;
  };

  services.nginx.enable = true;
  services.red-door-collective.rdc-website.enable = true;
  nixpkgs.overlays = [inputs.rdc-website.overlays.default];

  security.acme = {
    acceptTerms = true;
    defaults.email = "greg.ziegan@gmail.com";
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    authentication = ''
      local rdc_website rdc_website md5
    '';
    ensureUsers = [
      {
        name = "grafana";
      }
      {
        name = "postgres_exporter";
      }
    ];
  };

  # currently broken. should fix for one-stop rdc monitoring and db setup
  # systemd.services.ensure-db-permissions = {
  #   description = "Ensure appropriate users have permissions on rdc_website";
  #   wantedBy = ["rdc-website.service"];
  #   before = ["rdc-website.service"];
  #   requires = ["postgresql.service"];
  #   script = ''
  #     PSQL="${config.services.postgresql.package}/bin/psql --port=${toString config.services.postgresql.port}"
  #     for i in {1..10}; do
  #       $PSQL -d postgres -c "" 2> /dev/null && break
  #       sleep 0.5
  #       if [[ $i -eq 10 ]];then
  #         echo "couldn't establish connection to postgres"
  #         exit 1
  #     fi
  #     done
  #       $PSQL -tAc 'GRANT USAGE ON SCHEMA public TO grafana'
  #       $PSQL -tAc 'GRANT SELECT ON ALL TABLES IN SCHEMA public TO grafana'
  #       $PSQL -tAc 'CREATE USER postgres_exporter'
  #       $PSQL -tAc 'GRANT pg_monitor to postgres_exporter'
  #   '';
  #   serviceConfig = {
  #     Type = "oneshot";
  #   };
  # };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [80 443];
  networking.firewall.allowedUDPPorts = [80 443];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  system.autoUpgrade = {
    flake = "github:gregziegan/nixos-flake-configs";
    randomizedDelaySec = "15m";
    dates = "daily";

    operation = "boot";
    allowReboot = true;
    rebootWindow = {
      lower = "22:00";
      upper = "23:59";
    };
  };
}
