{
  description = "My deploy-rs config for fred";

  inputs = {
    # NixOS official package source, using the nixos-23.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    agenix.url = "github:ryantm/agenix";
    deploy-rs.url = "github:serokell/deploy-rs";
    # rdc-website = {
    #   url = "github:red-door-collective/rdc-website/main-deploy";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    rdc-website = {
      url = "git+file:/Users/gziegan/dev/rdc-website?ref=main-deploy";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11"; # this selects the release-branch and needs to match Nixpkgs
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    deploy-rs,
    home-manager,
    agenix,
    rdc-website,
    ...
  } @ inputs: let
    pkgs = nixpkgs.legacyPackages."x86_64-linux";

    mkSystem = extraModules:
      nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        modules =
          [
            agenix.nixosModules.age
            home-manager.nixosModules.home-manager

            ({config, ...}: {
              system.configurationRevision = self.sourceInfo.rev;
              services.getty.greetingLine = "<<< Welcome to NixOS ${config.system.nixos.label} @ ${self.sourceInfo.rev} - \\l >>>";

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            })

            ./common
          ]
          ++ extraModules;
      };
  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = [
        agenix.packages.x86_64-linux.agenix
      ];
    };

    nixosModules = {
      home-manager = import ./common/home-manager;
    };

    nixosConfigurations = {
      fred = mkSystem [
        ./hosts/fred
        ({...}: {
          imports = [
            rdc-website.nixosModules.default
            ./common/services/rdc-website.nix
          ];
          nixpkgs.overlays = [rdc-website.overlays.default];
        })
      ];
      sankara = mkSystem [
        ./hosts/sankara
      ];
    };

    deploy.nodes.fred = {
      hostname = "192.168.86.27";
      sshUser = "root";
      fastConnection = true;

      profiles.system = {
        user = "root";
        path =
          deploy-rs.lib.x86_64-linux.activate.nixos
          self.nixosConfigurations.fred;
      };
    };

    deploy.nodes.sankara = {
      hostname = "192.168.86.44";
      sshUser = "root";
      fastConnection = true;

      profiles.system = {
        user = "root";
        path =
          deploy-rs.lib.x86_64-linux.activate.nixos
          self.nixosConfigurations.sankara;
      };
    };

    # This is highly advised, and will prevent many possible mistakes
    checks =
      builtins.mapAttrs
      (system: deployLib: deployLib.deployChecks self.deploy)
      deploy-rs.lib;
  };
}
