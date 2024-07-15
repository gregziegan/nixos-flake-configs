{
  description = "My deploy-rs config for fred";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
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
      url = "github:nix-community/home-manager/release-24.05"; # this selects the release-branch and needs to match Nixpkgs
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-24.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    devenv.url = "github:cachix/devenv/latest";

    # Environment/system management
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";

    # rust, see https://github.com/nix-community/fenix#usage
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = {
    self,
    nixpkgs,
    deploy-rs,
    home-manager,
    agenix,
    rdc-website,
    devenv,
    fenix,
    darwin,
    ...
  } @ inputs: let
    inherit (darwin.lib) darwinSystem;
    inherit (inputs.nixpkgs-darwin.lib) attrValues makeOverridable optionalAttrs singleton;

    # Configuration for `nixpkgs`
    nixpkgsConfig = {
      config = {allowUnfree = true;};
      overlays =
        attrValues self.overlays
        ++ singleton (
          # Sub in x86 version of packages that don't build on Apple Silicon yet
          final: prev: (optionalAttrs (prev.stdenv.system == "aarch64-darwin") {
            inherit
              (final.pkgs-x86)
              nix-index
              ;
          })
        );
    };

    pkgs = nixpkgs.legacyPackages."x86_64-linux";

    rev = self.rev or self.dirtyRev or "dirty";

    mkSystem = extraModules:
      nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules =
          [
            agenix.nixosModules.age
            home-manager.nixosModules.home-manager

            ({config, ...}: {
              system.configurationRevision = rev;
              services.getty.greetingLine = "<<< Welcome to NixOS ${config.system.nixos.label} @ ${rev} - \\l >>>";

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            })

            ./common
          ]
          ++ extraModules;
      };

    shellHook = ''
      echo "Nix flake revision is ${rev}"
      echo "nixpkgs revision is ${nixpkgs.rev}"
    '';
  in {
    overlays = {
      # Overlay useful on Macs with Apple Silicon
      apple-silicon = final: prev:
        optionalAttrs (prev.stdenv.system == "aarch64-darwin") {
          # Add access to x86 packages system is running Apple Silicon
          pkgs-x86 = import inputs.nixpkgs-unstable {
            system = "x86_64-darwin";
            inherit (nixpkgsConfig) config;
          };
        };
    };

    devShells.x86_64-linux.default = pkgs.mkShell {
      inherit shellHook;
      packages = [
        agenix.packages.x86_64-linux.agenix
      ];
    };

    devShells.aarch64-darwin.default = nixpkgs.legacyPackages.aarch64-darwin.mkShell {
      inherit shellHook;
      packages = [
        agenix.packages.aarch64-darwin.agenix
      ];
    };

    nixosModules = {
      home-manager = import ./common/home-manager;
    };

    nixosConfigurations = {
      fred = mkSystem [./hosts/fred];
      sankara = mkSystem [./hosts/sankara];
    };

    darwinConfigurations = rec {
      specialArgs = {
        inherit devenv fenix;
      };

      che = darwinSystem {
        system = "aarch64-darwin";

        modules = [
          # Main `nix-darwin` config
          ./hosts/che
          # `home-manager` module
          home-manager.darwinModules.home-manager
          {
            nixpkgs = nixpkgsConfig;
            # `home-manager` config
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.gziegan = import ./common/home-manager/gziegan;
            home-manager.extraSpecialArgs = specialArgs;
          }
        ];
      };
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

    deploy.nodes.che = {
      remoteBuild = true;

      hostname = "192.168.86.29";
      sshUser = "root";
      fastConnection = true;

      profiles.system = {
        user = "root";
        path =
          deploy-rs.lib.aarch64-darwin.activate.darwin
          self.darwinConfigurations.che;
      };
    };

    # This is highly advised, and will prevent many possible mistakes
    checks =
      builtins.mapAttrs
      (system: deployLib: deployLib.deployChecks self.deploy)
      deploy-rs.lib;
  };
}
