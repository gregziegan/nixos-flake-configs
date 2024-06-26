{ config, pkgs, ... }:

{
  users.users.gziegan = {
    isNormalUser = true;
    description = "Greg Ziegan";
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhQYc5LT5giAndbsAoMC9/bVUhDWcD4pm4am8BMEK55 greg.ziegan@gmail.com"
    ];
    packages = with pkgs; [
      firefox
      chromium
      vscode
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = config.users.users.gziegan.openssh.authorizedKeys.keys;
  home-manager.users.gziegan = (import ./gziegan);
}
