{
  description = "Simple application for displaying CPU/RAM usage on the Framework 16 LED Matrix modules";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";  
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ (import rust-overlay) ];
      };
      appPackage = pkgs.rustPlatform.buildRustPackage {
        pname = "led-matrix-sysinfo";
        version = "1.0.0";
        src = ./.;
        cargoLock.lockFile = ./Cargo.lock;
        nativeBuildInputs = with pkgs; [ pkg-config ];
        buildInputs = with pkgs; [ systemd ];
        meta = with pkgs.lib; {
          description = "Simple test application for the Framework 16 LED Matrix modules";
          license = licenses.mit;
          maintainers = [];
          platforms = platforms.linux;
        };
      };
      nixosModule = import ./led-matrix-sysinfo.nix {
          inherit pkgs;
          lib = pkgs.lib;
          config = {};
          system = system;
          appPackage = appPackage;  # pass the built package to the module
        };
    in {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [ pkg-config ];
        buildInputs = with pkgs; [ systemd.dev rust-bin.nightly.latest.default cargo ];
      };
      packages.default = appPackage;
      nixosModules.default = nixosModule;
    }
  );
}