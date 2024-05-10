{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
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

  networking.hostName = "fred"; # Define your hostname.

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
  ];

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

  # services.red-door-collective.enable = true;

  # services.nginx = {
  #   enable = true;
  #   virtualHosts = {
  #     "reddoorcollective.online" = {
  #       default = true;
  #       locations."/" = {
  #         proxyPass = "http://127.0.0.1:8080";
  #       };
  #       addSSL = true;
  #       enableACME = true;
  #     };
  #   };
  # };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    initialScript = pkgs.writeText "rdc-init.sql" ''
      CREATE ROLE "fred-rdc" WITH LOGIN PASSWORD 'rdc' CREATEDB;
      CREATE DATABASE "fred-rdc" WITH OWNER "fred-rdc";
    '';
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ 80 443 ];

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
