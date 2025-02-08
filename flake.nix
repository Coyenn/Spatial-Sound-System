{
  description = "Development environment with Bun and Rokit";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };

        rokit = pkgs.rustPlatform.buildRustPackage {
          pname = "rokit";
          version = "v1.0.0";

          src = pkgs.fetchFromGitHub {
            owner = "rojo-rbx";
            repo = "rokit";
            rev = "main";
            sha256 = "sha256-cGsxfz3AT8W/EYk3QxVfZ8vd6zGNx1Gn6R1SWCYbVz0=";
          };

          cargoHash = "sha256-Z/egZ/OC68GbJjwMOrCrUX2JWMqXwppoSzz0q4Nbg+A=";
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.bun
            rokit
          ];

          shellHook = ''
            # Add rokit bin directory to PATH
            export PATH="$HOME/.rokit/bin:$PATH"

            # Create directory if it doesn't exist
            mkdir -p "$HOME/.rokit/bin"

            echo "Welcome to development shell!"
            echo "Installed tools:"
            echo " - Bun $(bun --version)"
            echo " - Rokit $(rokit --version)"
          '';
        };
      }
    );
}
