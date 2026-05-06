{
  description = "PCRE bindings for OCaml";
  inputs = {
    opam-nix.url = "github:tweag/opam-nix";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    opam-repository = {
      url = "github:ocaml/opam-repository";
      flake = false;
    };
  };
  outputs = { self, flake-utils, opam-nix, nixpkgs, opam-repository }:
    let package = "pcre";
    in flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        on = opam-nix.lib.${system};
        opamRepos = [ "${opam-repository}" ];
      in let
        devOpamPackagesQuery = {
          # "development" ocaml packages — added to the devShell automatically.
          ocaml-lsp-server = "*";
          utop = "*";
          ocamlformat = "*";
          merlin = "*";
          # pulled in for the optional pcre_bin_prot sub-library + tests
          bin_prot = "*";
          ppx_bin_prot = "*";
        };
        opamQuery = devOpamPackagesQuery // {
          ocaml-base-compiler = "4.14.2";
          # ounit2 is a :with-test dep on the pcre package; opam-nix's
          # buildOpamProject' doesn't pick that up, so force it here.
          ounit2 = "*";
        };

        scope = on.buildOpamProject' { repos = opamRepos; } ./. opamQuery;
        scopeOverlay = final: prev: {
          ${package} = prev.${package}.overrideAttrs (prev: {
            doNixSupport = false;
            buildInputs = prev.buildInputs
              ++ [ final.ounit2 final.bin_prot final.ppx_bin_prot ];
          });
        };
        scope' = scope.overrideScope scopeOverlay;

        devOpamPackages = builtins.attrValues
          (pkgs.lib.getAttrs (builtins.attrNames devOpamPackagesQuery) scope');

        baseOpamPackage = scope'.${package};

        pcre = baseOpamPackage.overrideAttrs (prev: rec {
          pname = "pcre";
          buildInputs = prev.buildInputs;
          buildPhase' = ''
            dune build
          '';
        });
      in {

        packages.pcre = pcre;

        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          shellHook = with pkgs; ''
            export NIX_CXXFLAGS_COMPILE="$NIX_CXXFLAGS_COMPILE -I${pkgs.libcxx.dev}/include/c++/v1"
          '';
          inputsFrom = [ pcre ];
          buildInputs = devOpamPackages;
        };
      });
}
