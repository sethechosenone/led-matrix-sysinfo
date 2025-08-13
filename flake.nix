{
  description = "Simple application for displaying CPU/RAM usage on the Framework 16 LED Matrix modules";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        led-matrix-sysinfo = pkgs.rustPlatform.buildRustPackage {
          pname = "led-matrix-sysinfo";
          version = "1.0.0";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
          nativeBuildInputs = with pkgs; [ pkg-config ];
          buildInputs = with pkgs; [ systemd ];
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
          buildInputs = with pkgs; [ systemd.dev rust-bin.nightly.latest.default cargo ];
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
            };
          };

          config = with lib; let
            cfg = config.services.led-matrix-sysinfo;
            
            led-matrix-sysinfo = pkgs.rustPlatform.buildRustPackage {
              pname = "led-matrix-sysinfo";
              version = "1.0.0";
              src = self;
              cargoLock.lockFile = "${self}/Cargo.lock";
              nativeBuildInputs = with pkgs; [ pkg-config ];
              buildInputs = with pkgs; [ systemd ];
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
                Type = "simple";
              };
            };
          };
        };

        led-matrix-sysinfo = self.nixosModules.default;
      };
    };
}