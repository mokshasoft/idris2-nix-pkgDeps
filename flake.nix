{
  description = "My Idris 2 program";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.idris = {
    url = "github:idris-lang/Idris2";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };
  inputs.pkg = {
    url = "github:idris-community/idris2-getopts";
    flake = false; # Indicating that this is not a flake.
  };

  outputs = { self, nixpkgs, idris, flake-utils, pkg }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        idrisPkgs = idris.packages.${system};
        buildIdris = idris.buildIdris.${system};

        # Package the idris2-getopts library
        getoptsLibrary = buildIdris {
          ipkgName = "getopts";
          src = "${pkg}";  # Use the source of the idris2-getopts repo
          idrisLibraries = [ ]; # Assuming getopts doesn't have further dependencies
        };

        # Build your package with the dependency on idris2-getopts
        myPackage = buildIdris {
          ipkgName = "pkgWithDeps";
          src = ./.;
          idrisLibraries = [ getoptsLibrary ];
        };

      in rec {
        # The default package to be built
        packages.default = myPackage.executable;

        # Configure nix run to execute the binary
        apps.default = {
          type = "app";
          program = "${myPackage.executable}/bin/runMyPkg2";
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

