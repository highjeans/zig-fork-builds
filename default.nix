let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {
    overlays = [ ];
    config = {
      microsoftVisualStudioLicenseAccepted = true;
    };
  };
in
{
  default = pkgs.callPackage ./package.nix { };
  windows = pkgs.pkgsCross.x86_64-windows.callPackage ./package.nix { };
}
