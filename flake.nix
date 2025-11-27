{
  description = "Simple application for displaying CPU/RAM usage on the Framework 16 LED Matrix modules";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        led-matrix-sysinfo = pkgs.stdenv.mkDerivation {
          pname = "led-matrix-sysinfo";
          version = "1.0.0";

          src = pkgs.fetchurl {
            url = "https://github.com/sethechosenone/led-matrix-sysinfo/releases/latest/download/led-matrix-sysinfo";
            sha256 = "sha256-IvKdA39M/Jes0FWmA7XR7vG8qL/GMVRHtM2gxuzBnLo=";
          };

          dontUnpack = true;

          nativeBuildInputs = [ pkgs.autoPatchelfHook ];
          buildInputs = [ pkgs.systemd ];

          installPhase = ''
            mkdir -p $out/bin
            cp $src $out/bin/led-matrix-sysinfo
            chmod +x $out/bin/led-matrix-sysinfo
          '';

          meta = with pkgs.lib; {
            description = "Simple application for displaying CPU/RAM usage on the Framework 16 LED Matrix modules";
            license = licenses.mit;
            maintainers = [];
            platforms = platforms.linux;
          };
        };
      in
      {
        packages = {
          default = led-matrix-sysinfo;
          led-matrix-sysinfo = led-matrix-sysinfo;
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ pkg-config ];
          buildInputs = with pkgs; [ systemd.dev rust-bin.nightly.latest.default cargo rustfmt rust-analyzer ];
        };
      }
    ) // {
      nixosModules = {
        default = { config, lib, pkgs, ... }: {
          imports = [ ];
          
          options = with lib; {
            services.led-matrix-sysinfo = {
              enable = mkEnableOption "LED Matrix System Info service";
              interval = mkOption {
                type = types.int;
                default = 1000;
                description = "Update interval in milliseconds";
              };
              timeBeforeRestart = mkOption {
                type = types.int;
                default = 5;
                description = "Time in seconds to wait until restarting upon crash";
              };
            };
          };

          config = with lib; let
            cfg = config.services.led-matrix-sysinfo;
            
            led-matrix-sysinfo = pkgs.stdenv.mkDerivation {
              pname = "led-matrix-sysinfo";
              version = "1.0.0";

              src = pkgs.fetchurl {
                url = "https://github.com/sethechosenone/led-matrix-sysinfo/releases/latest/download/led-matrix-sysinfo";
                sha256 = "sha256-IvKdA39M/Jes0FWmA7XR7vG8qL/GMVRHtM2gxuzBnLo=";
              };

              dontUnpack = true;

              nativeBuildInputs = [ pkgs.autoPatchelfHook ];
              buildInputs = [ pkgs.systemd ];

              installPhase = ''
                mkdir -p $out/bin
                cp $src $out/bin/led-matrix-sysinfo
                chmod +x $out/bin/led-matrix-sysinfo
              '';

              meta = with pkgs.lib; {
                description = "Simple application for displaying CPU/RAM usage on the Framework 16 LED Matrix modules";
                license = licenses.mit;
                maintainers = [];
                platforms = platforms.linux;
              };
            };
          in mkIf cfg.enable {
            systemd.services.led-matrix-sysinfo = {
              description = "LED Matrix sysinfo service";
              after = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                ExecStart = "${led-matrix-sysinfo}/bin/led-matrix-sysinfo ${toString cfg.interval}";
                Restart = "on-failure";
                RestartSec = cfg.timeBeforeRestart;
                Type = "simple";
              };
            };
          };
        };

        led-matrix-sysinfo = self.nixosModules.default;
      };
    };
}
