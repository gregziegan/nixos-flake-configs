{
  config,
  lib,
  pkgs,
  ...
}: {
  services.nginx = {
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
        }
      ];
    };
  };
}
