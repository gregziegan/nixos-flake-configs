{ config, pkgs, lib, ... }:

with lib;

let cfg = config.red-door-collective.users.enableSystem;
in {
  options.red-door-collective.users = {
    enableSystem = mkEnableOption "enable system-wide users (vic, mai)";
  };

  config = mkIf cfg { };
}
