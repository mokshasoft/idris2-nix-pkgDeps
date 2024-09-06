{
  description = "My Idris 2 program with multiple dependencies";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    idris = {
      url = "github:idris-lang/Idris2";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    # Define dependencies in inputs
    getopts = {
      url = "github:idris-community/idris2-getopts";
      flake = false;
    };
    elab-util = {
      url = "github:stefan-hoeck/idris2-elab-util";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, idris, flake-utils, getopts, elab-util }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        idrisPkgs = idris.packages.${system};
        buildIdris = idris.buildIdris.${system};
        lib = nixpkgs.lib;  # Import lib

        # A function to package dependencies
        packageDependency = dep:
          buildIdris {
            ipkgName = dep.name;
            src = dep.src;
            idrisLibraries = [];
          };

        # Dependencies in a set for mapAttrs
        dependencies = {
          getopts = {
            name = "getopts";
            src = getopts;
          };
          elab-util = {
            name = "elab-util";
            src = elab-util;
          };
        };

        # Iterate over all dependencies and build them
        builtDeps = lib.attrValues (lib.mapAttrs (name: dep: packageDependency dep) dependencies);

        # Build your package with dependencies
        myPackage = buildIdris {
          ipkgName = "pkgWithDeps";
          src = ./.;
          idrisLibraries = builtDeps;
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

