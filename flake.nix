{
  description = "My Idris 2 program with multiple dependencies";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    idris = {
      url = "github:idris-lang/Idris2";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    # Define dependencies here
    getopts = {
      url = "github:idris-community/idris2-getopts";
      flake = false;
    };
    elab-util = {
      url = "github:stefan-hoeck/idris2-elab-util";
      flake = false;
    };
    filepath = {
      url = "github:stefan-hoeck/idris2-filepath";
      flake = false;
    };
    parser-toml = {
      url = "github:cuddlefishie/toml-idr";
      flake = false;
    };
    idris2-lib = {
      url = "github:idris-lang/Idris2";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, idris, flake-utils, getopts, elab-util, filepath, parser-toml, idris2-lib }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        idrisPkgs = idris.packages.${system};
        buildIdris = idris.buildIdris.${system};
        lib = nixpkgs.lib;  # Import lib

        # Function to build a dependency package
        buildDependency = { name, src }: buildIdris {
          ipkgName = name;
          src = src;
          idrisLibraries = [];
        };

        # List of dependencies
        dependencies = {
          getopts = buildDependency {
            name = "getopts";
            src = getopts;
          };
          elab-util = buildDependency {
            name = "elab-util";
            src = elab-util;
          };
          filepath = buildDependency {
            name = "filepath";
            src = filepath;
          };
          parser-toml = buildDependency {
            name = "toml";
            src = parser-toml;
          };
          idris2-lib = buildDependency {
            name = "idris2";
            src = idris2-lib;
          };
        };

        # Convert dependencies from set to list
        builtDeps = lib.attrValues dependencies;

        # Build the main package with its dependencies
        myPackage = buildIdris {
          ipkgName = "pkgWithDeps";
          src = ./.;
          idrisLibraries = builtDeps;
        };

      in {
        # Default package to be built
        packages.default = myPackage.executable;

        # Application configuration for running the binary
        apps.default = {
          type = "app";
          program = "${myPackage.executable}/bin/runMyPkg2";
        };

        # Development shell configuration
        devShell = pkgs.mkShell {
          buildInputs = [ idrisPkgs.idris2 pkgs.rlwrap ];
          shellHook = ''
            alias idris2="rlwrap -s 1000 idris2 --no-banner"
          '';
        };
      });
}

