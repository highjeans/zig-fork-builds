let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {
    overlays = [ ];
    config = {
    };
  };
in
pkgs.callPackage ./package.nix { }
