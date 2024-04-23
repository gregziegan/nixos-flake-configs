{ config, lib, pkgs, ... }: {
  imports = [ ./users ./no-rsa-ssh-hostkey.nix ];

  boot.tmp.cleanOnBoot = true;
  boot.kernelModules = [ ];

  environment.systemPackages = with pkgs; [
    age
    minisign
    jq
    git
    nodejs-18_x
    btop
  ];

  # security.polkit.enable = true;

  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    settings = {
      auto-optimise-store = true;
      sandbox = true;
      trusted-users = [ "root" "nginx" ];
    };
  };

  security.pam.loginLimits = [{
    domain = "*";
    type = "soft";
    item = "nofile";
    value = "unlimited";
  }];

  services.journald.extraConfig = ''
    SystemMaxUse=100M
    MaxFileSec=7day
  '';

  systemd.services.nginx.serviceConfig.SupplementaryGroups = "red-door-collective";

  users.groups.red-door-collective = { };
  systemd.services."red-door-collective.homedir-setup" = {
    description = "Creates homedirs for /srv/red-door-collective services";
    wantedBy = [ "multi-user.target" ];

    serviceConfig.Type = "oneshot";

    script = with pkgs; ''
      ${coreutils}/bin/mkdir -p /srv/red-door-collective
      ${coreutils}/bin/chown root:red-door-collective /srv/red-door-collective
      ${coreutils}/bin/chmod 775 /srv/red-door-collective
      ${coreutils}/bin/mkdir -p /srv/red-door-collective/run
      ${coreutils}/bin/chown root:red-door-collective /srv/red-door-collective/run
      ${coreutils}/bin/chmod 770 /srv/red-door-collective/run
    '';
  };

  system.stateVersion = lib.mkDefault "21.05";
}
