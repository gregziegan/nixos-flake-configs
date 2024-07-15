{
  config,
  lib,
  pkgs,
  ...
}: let
  rulerConfig = {
    groups = [
      {
        name = "production_rules";
        limit = 10;
        interval = "1m";
        rules = [
          {
            alert = "HighPercentageError";
            expr = ''              sum(rate({app="rdc-website", env="production"} |= "error" [5m])) by (job)
                          /
                        sum(rate({app="rdc-website", env="production"}[5m])) by (job)
                          > 0.05'';
            for = "10m";
            annotations.summary = ''High request latency'';
          }

          {
            record = "nginx:requests:rate1m";
            expr = ''
              sum(
                rate({container="nginx"}[1m])
              )'';
            labels.cluster = "us-central1";
          }
        ];
      }
    ];
  };
  rulerFile = pkgs.writeText "ruler.yml" (builtins.toJSON rulerConfig);
in {
  systemd.tmpfiles.rules = [
    "d /var/lib/loki 0700 loki loki - -"
    "d /var/lib/loki/ruler 0700 loki loki - -"
    "L /var/lib/loki/ruler/ruler.yml - - - - ${rulerFile}"
  ];
  systemd.services.loki.reloadTriggers = [rulerFile];

  services.loki = {
    enable = true;
    configuration = {
      server.http_listen_port = 3030;
      auth_enabled = false;

      ingester = {
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore = {
              store = "inmemory";
            };
            replication_factor = 1;
          };
        };
        chunk_idle_period = "1h";
        max_chunk_age = "1h";
        chunk_target_size = 999999;
        chunk_retain_period = "30s";
      };

      schema_config = {
        configs = [
          {
            from = "2024-04-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };

      storage_config = {
        tsdb_shipper = {
          active_index_directory = "/var/lib/loki/tsdb-active";
          cache_location = "/var/lib/loki/tsdb-shipper-cache";
          cache_ttl = "24h";
        };

        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };

      limits_config = {
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
      };

      compactor = {
        working_directory = "/var/lib/loki";
        compactor_ring = {
          kvstore = {
            store = "inmemory";
          };
        };
      };

      ruler = {
        storage = {
          type = "local";
          local.directory = "${config.services.loki.dataDir}/ruler";
        };
        rule_path = "/var/lib/loki/rules";
        alertmanager_url = "http://localhost";
        enable_api = true;
        ring = {
          kvstore = {
            store = "inmemory";
          };
        };
      };
    };
    # user, group, dataDir, extraFlags, (configFile)
  };
}
