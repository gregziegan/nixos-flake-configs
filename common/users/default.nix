{ config, pkgs, lib, ... }:

with lib;

{
  imports = [ ./gziegan.nix ./other.nix ];
}
