{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.red-door-collective.users.enableSystem;
in {
  config = mkIf cfg {};
}
