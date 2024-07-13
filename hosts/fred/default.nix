{
  pkgs,
  config,
  ...
}: let
  hostName = "fred";

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
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };

      efi.canTouchEfiVariables = true;
    };
  };

  services.red-door-collective.rdc-website.enable = true;

  networking.hostName = hostName;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
  ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
    };
    openFirewall = true;
  };

  services.nginx = {
    enable = true;
    virtualHosts.${config.services.grafana.settings.server.domain} = {
      addSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
      };
    };
  };

  services.grafana = {
    enable = true;
    settings.server = {
      domain = "reddoorcollective.online";
      http_port = 2342;
      http_addr = "127.0.0.1";
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
        }
        {
          name = "Loki";
          type = "loki";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
        }
        {
          name = "RDC Website Postgres";
          type = "postgres";
          url = "/run/postgresql";
          database = "rdc_website";
          user = "grafana";
          jsonData = {
            postgresVersion = 1500;
          };
          # orgId = 1;
        }
      ];
    };
  };

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
        openFirewall = true;
        extraFlags = ["--auto-discover-databases"];
      };
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
    ];
  };

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
        max_transfer_retries = 0;
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
          shared_store = "filesystem";
        };

        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };

      limits_config = {
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
      };

      chunk_store_config = {
        max_look_back_period = "0s";
      };

      compactor = {
        working_directory = "/var/lib/loki";
        shared_store = "filesystem";
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
        ring = {
          kvstore = {
            store = "inmemory";
          };
          enable_api = true;
        };
      };
    };
    # user, group, dataDir, extraFlags, (configFile)
  };

  # promtail: port 3031 (8031)
  #
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 3031;
        grpc_listen_port = 0;
      };
      positions = {
        filename = "/tmp/positions.yaml";
      };
      clients = [
        {
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
        }
      ];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = hostName;
            };
          };
          relabel_configs = [
            {
              source_labels = ["__journal__systemd_unit"];
              target_label = "unit";
            }
          ];
        }
      ];
    };
    # extraFlags
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "greg.ziegan@gmail.com";
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    authentication = ''
      local rdc_website rdc_website md5
    '';
    ensureDatabases = ["rdc_website"];
    ensureUsers = [
      {
        name = "rdc_website";
        ensureDBOwnership = true;
      }
      {
        name = "grafana";
      }
    ];
  };

  systemd.services.ensure-db-permissions = {
    description = "Ensure appropriate users have permissions on rdc_website";
    wantedBy = ["rdc-website.service"];
    before = ["rdc-website.service"];
    requires = ["postgresql.service"];
    script = ''
      PSQL="${config.services.postgresql.package}/bin/psql --port=${toString config.services.postgresql.port}"
      for i in {1..10}; do
        $PSQL -d postgres -c "" 2> /dev/null && break
        sleep 0.5
        if [[ $i -eq 10 ]];then
          echo "couldn't establish connection to postgres"
          exit 1
      fi
      done
        $PSQL -tAc 'GRANT USAGE ON SCHEMA public TO grafana'
        $PSQL -tAc 'GRANT SELECT ON ALL TABLES IN SCHEMA public TO grafana'
    '';
    serviceConfig = {
      type = "oneshot";
    };
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [80 443];
  networking.firewall.allowedUDPPorts = [80 443];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  system.autoUpgrade = {
    flake = "github:gregziegan/nixos-flake-configs";
    randomizedDelaySec = "15m";
    dates = "daily";

    operation = "boot";
    allowReboot = true;
    rebootWindow = {
      lower = "22:00";
      upper = "23:59";
    };
  };
}
