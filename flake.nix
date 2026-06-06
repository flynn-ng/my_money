{
  description = "Money manager flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShellNoCC
          {
            buildInputs = with pkgs; [
              flutter
              dart
              cocoapods
            ];
            shellHook = ''
              chmod -R u+w ios/ build/ 2>/dev/null || true
            '';
          };
      }
    );
}
