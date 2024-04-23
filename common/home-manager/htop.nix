{ lib, config, pkgs, ... }:

with lib;

let cfg = config.red-door-collective.htop;
in {
  options.red-door-collective.htop.enable = mkEnableOption "htop";
  config = mkIf cfg.enable {
    programs.htop.enable = true;
  };
}
