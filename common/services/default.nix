{ config, lib, pkgs, ... }:

{
  imports = [
    ./red-door-collective.nix
  ];

  users.groups.within = { };
}
