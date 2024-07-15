{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./grafana.nix
    ./loki.nix
    ./prometheus.nix
    ./promtail.nix
  ];
}
