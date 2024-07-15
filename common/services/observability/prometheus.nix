{
  config,
  lib,
  pkgs,
  ...
}: let
  hostName = config.networking.hostName;
in {
  services.prometheus = {
    enable = true;
    port = 9001;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = ["systemd"];
        port = 9002;
      };
      postgres = {
        enable = true;
        # user = "postgres_exporter";
        openFirewall = true;
        dataSourceName = "user=postgres_exporter database=postgres host=/run/postgresql sslmode=disable";
        # environmentFile = "/root/prometheus-postgres-exporter.env";
      };
      # nginx?
      # python?
      # statsd?
      # graphite?
    };

    scrapeConfigs = [
      {
        job_name = hostName;
        static_configs = [
          {
            targets = ["127.0.0.1:${toString config.services.prometheus.exporters.node.port}"];
          }
        ];
      }

      {
        job_name = "postgres";
        scrape_interval = "15s";
        static_configs = [
          {
            targets = ["localhost:${toString config.services.prometheus.exporters.postgres.port}"];
            labels = {
              server = hostName;
            };
          }
        ];
      }

      {
        job_name = "rdc-website";
        scrape_interval = "3s";
        static_configs = [
          {
            targets = ["localhost:${toString config.services.red-door-collective.rdc-website.metricsPort}"];
            labels = {
              server = hostName;
            };
          }
        ];
      }
    ];
  };
}