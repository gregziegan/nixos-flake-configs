{ ... }:

{
  imports = [
    ./htop.nix
    ./vim
  ];

  programs.git.lfs.enable = true;

  nixpkgs.config = {
    allowBroken = true;
    allowUnfree = true;

    manual.manpages.enable = true;
  };

  systemd.user.startServices = true;

  programs.atuin.enable = true;

  home.stateVersion = "24.05";
}
