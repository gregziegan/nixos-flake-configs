{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [./users ./no-rsa-ssh-hostkey.nix];

  boot.tmp.cleanOnBoot = true;
  boot.kernelModules = [];

  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

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

  environment.systemPackages = with pkgs; [
    age
    minisign
    jq
    git
    nodejs-18_x
    btop
    toybox
    vim
    deploy-rs
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
      trusted-users = ["root" "nginx" "gziegan"];
    };
  };

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "unlimited";
    }
  ];

  services.journald.extraConfig = ''
    SystemMaxUse=100M
    MaxFileSec=7day
  '';

  system.stateVersion = lib.mkDefault "23.11";
}
