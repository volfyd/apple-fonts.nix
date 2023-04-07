{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      unpackPhase = pkgName: ''
        case "$src" in
          *.dmg)
            undmg $src
            7z x '${pkgName}'
            7z x 'Payload~'
            ;;
          *.ttf)
            fontforge -lang=pe -c "Open(\$1);Select('fi');SelectMore('fl');DetachAndRemoveGlyphs();Generate('${pkgName}')" "$src"
            ;;
        esac
      '';
      commonInstall = ''
        mkdir -p $out/share/fonts
        mkdir -p $out/share/fonts/opentype
        mkdir -p $out/share/fonts/truetype
      '';
      commonBuildInputs = with pkgs; [undmg p7zip fontforge];
      makeAppleFont = name: pkgName: src:
        pkgs.stdenv.mkDerivation {
          inherit name src;

          unpackPhase = unpackPhase pkgName;

          buildInputs = commonBuildInputs;
          setSourceRoot = "sourceRoot=`pwd`";

          installPhase =
            commonInstall
            + ''
              find -name \*.otf -exec mv {} $out/share/fonts/opentype/ \;
              find -name \*.ttf -exec mv {} $out/share/fonts/truetype/ \;
            '';
        };
      makeNerdAppleFont = name: pkgName: src:
        pkgs.stdenv.mkDerivation {
          inherit name src;

          unpackPhase = unpackPhase pkgName;

          buildInputs = with pkgs;
            commonBuildInputs ++ [parallel nerd-font-patcher];
          setSourceRoot = "sourceRoot=`pwd`";

          buildPhase = ''
            find \( -name \*.ttf -o -name \*.otf \) -print0 | parallel -j $NIX_BUILD_CORES -0 nerd-font-patcher -c {}
          '';

          installPhase =
            commonInstall
            + ''
              find -name \*.otf -maxdepth 1 -exec mv {} $out/share/fonts/opentype/ \;
              find -name \*.ttf -maxdepth 1 -exec mv {} $out/share/fonts/truetype/ \;
            '';
        };
    in rec {
      packages = let
        sf-pro-src = {
          url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
          hash = "sha256-g/eQoYqTzZwrXvQYnGzDFBEpKAPC8wHlUw3NlrBabHw=";
        };
        sf-compact-src = {
          url = "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg";
          hash = "sha256-0mUcd7H7SxZN3J1I+T4SQrCsJjHL0GuDCjjZRi9KWBM=";
        };
        sf-mono-src = {
          url = "https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg";
          hash = "sha256-q69tYs1bF64YN6tAo1OGczo/YDz2QahM9Zsdf7TKrDk=";
        };
        sf-arabic-src = {
          url = "https://devimages-cdn.apple.com/design/resources/download/SF-Arabic.dmg";
          hash = "sha256-4tZhojq2qGG73t/DgYYVTN+ROFKWK2ubeNM53RbPS0E=";
        };
        ny-src = {
          url = "https://devimages-cdn.apple.com/design/resources/download/NY.dmg";
          hash = "sha256-HuAgyTh+Z1K+aIvkj5VvL6QqfmpMj6oLGGXziAM5C+A=";
        };
        menlo-src = {
          url = "https://github.com/cristianvogel/NEL_VCS/raw/9fbccaee876da301e5821b8287f850e55e18dcc7/resources/fonts/Menlo.ttf";
          hash = "sha256-BjAj2bj6V/2SWyOsYVuZSrBKFHlNyA/8jHJK+vRBKLM=";
        };
      in rec {
        sf-pro = makeAppleFont "sf-pro" "SF Pro Fonts.pkg" (pkgs.fetchurl sf-pro-src);
        sf-pro-nerd = makeNerdAppleFont "sf-pro-nerd" "SF Pro Fonts.pkg" (pkgs.fetchurl sf-pro-src);

        sf-compact = makeAppleFont "sf-compact" "SF Compact Fonts.pkg" (pkgs.fetchurl sf-compact-src);
        sf-compact-nerd = makeNerdAppleFont "sf-compact-nerd" "SF Compact Fonts.pkg" (pkgs.fetchurl sf-compact-src);

        sf-mono = makeAppleFont "sf-mono" "SF Mono Fonts.pkg" (pkgs.fetchurl sf-mono-src);
        sf-mono-nerd = makeNerdAppleFont "sf-mono-nerd" "SF Mono Fonts.pkg" (pkgs.fetchurl sf-mono-src);

        sf-arabic = makeAppleFont "sf-arabic" "SF Arabic Fonts.pkg" (pkgs.fetchurl sf-arabic-src);
        sf-arabic-nerd = makeNerdAppleFont "sf-arabic-nerd" "SF Arabic Fonts.pkg" (pkgs.fetchurl sf-arabic-src);

        ny = makeAppleFont "ny" "NY Fonts.pkg" (pkgs.fetchurl ny-src);
        ny-nerd = makeNerdAppleFont "ny-nerd" "NY Fonts.pkg" (pkgs.fetchurl ny-src);

        menlo = makeAppleFont "menlo" "Menlo.ttf" (pkgs.fetchurl menlo-src);
        menlo-nerd = makeNerdAppleFont "menlo-nerd" "Menlo.ttf" (pkgs.fetchurl menlo-src);
      };
    });
}
