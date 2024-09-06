{
  description = "My Idris 2 program";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.idris = {
    url = "github:idris-lang/Idris2";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { self, nixpkgs, idris, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        idrisPkgs = idris.packages.${system};
        buildIdris = idris.buildIdris.${system};

        # Build the Idris project using the buildIdris function
        myPackage = buildIdris {
          ipkgName = "pkgWithDeps";
          src = ./.;
          idrisLibraries = [ ];
        };

      in rec {
        # The default package to be built
        packages.default = myPackage.executable;

        # Configure nix run to execute the binary
        apps.default = {
          type = "app";
          program = "${myPackage.executable}/bin/runMyPkg";
        };

        # Development shell
        devShell = pkgs.mkShell {
          buildInputs = [ idrisPkgs.idris2 pkgs.rlwrap ];
          shellHook = ''
            alias idris2="rlwrap -s 1000 idris2 --no-banner"
          '';
        };
      });
}

