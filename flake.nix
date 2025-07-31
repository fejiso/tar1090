{
  description = "A Nix flake for tar1090";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        tar1090-db = pkgs.stdenv.mkDerivation rec {
          pname = "tar1090-db";
          version = "623e6e0";

          src = pkgs.fetchFromGitHub {
            owner = "wiedehopf";
            repo = "tar1090-db";
            rev = "623e6e03d2b2e521c91bfd961ae1ad3831065716";
            sha256 = "0kwmmng82ygjhs87pr3bki1bji201r9w71rss6w9hqyhwczj12ri";
          };

          installPhase = ''
            mkdir -p $out/db
            cp -r db/* $out/db
          '';
        };

        tar1090 = pkgs.stdenv.mkDerivation rec {
          pname = "tar1090";
          version = "80fb681";

          src = pkgs.fetchFromGitHub {
            owner = "wiedehopf";
            repo = "tar1090";
            rev = "80fb68198625ab042833a40a0d19bcc39c1c54a8";
            sha256 = "039bvrypvm648f5n7apc3c9rxns440751kmdi5dpgxn99axj2bik";
          };

          buildInputs = [ pkgs.jq pkgs.curl ];

          installPhase = ''
            mkdir -p $out/bin $out/share/tar1090
            cp tar1090.sh $out/bin/
            cp -r html $out/share/tar1090/
            ln -s ${tar1090-db}/db $out/share/tar1090/html/db
          '';
        };

        tar1090-module = { config, pkgs, lib, isTest ? false, ... }: {
          options = {
            services.tar1090 = {
              enable = lib.mkEnableOption "tar1090";

              instances = lib.mkOption {
                type = lib.types.attrsOf (lib.types.submodule ({
                  options = {
                    enable = lib.mkEnableOption "tar1090 instance";
                    dataSource = lib.mkOption {
                      type = lib.types.str;
                      description = "Path to the aircraft.json file.";
                    };
                    webPath = lib.mkOption {
                      type = lib.types.str;
                      default = "tar1090";
                      description = "The web path to access the instance.";
                    };
                  };
                }));
                default = {};
                description = "Configure tar1090 instances.";
              };
            };
          };

          config = lib.mkIf config.services.tar1090.enable {
            systemd.services =
              let
                enabledInstances = lib.filterAttrs (n: v: v.enable) config.services.tar1090.instances;
              in
              lib.mapAttrs' (name: instance:
                lib.nameValuePair "tar1090-${name}" {
                  description = "tar1090 instance: ${name}";
                  after = [ "network.target" ];
                  wants = [ "network.target" ];
                  serviceConfig = {
                    ExecStart = if isTest then "${pkgs.coreutils}/bin/sleep infinity" else "${tar1090}/bin/tar1090.sh ${instance.dataSource} ${instance.webPath}";
                    Restart = "always";
                    RestartSec = 30;
                  } // (lib.optionalAttrs (!isTest) {
                    User = "tar1090";
                    Group = "tar1090";
                  });
                }
              ) enabledInstances;

            users.users.tar1090 = {
              isSystemUser = true;
              group = "tar1090";
            };
            users.groups.tar1090 = {};

            environment.systemPackages = [ tar1090 ];
          };
        };

      in
      {
        packages.tar1090 = tar1090;
        nixosModules.default = tar1090-module;
        
      }
    );
}