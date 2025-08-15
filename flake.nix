# ~/nix-flakes/camoufox/flake.nix
{
  description = "A flake for packaging the Camoufox binary";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      camoufox-pkg = pkgs.stdenv.mkDerivation rec {
        pname = "camoufox";
        version = "135.0.1-beta.24";

        src = pkgs.fetchzip {
          url = "https://github.com/daijro/camoufox/releases/download/v${version}/camoufox-${version}-lin.x86_64.zip";
          sha256 = "sha256-k5t12L5q0RG8Zun0SAjGthYQXUcf+xVHvk9Mknr97QY=";
          stripRoot = false;
        };

        nativeBuildInputs = [
          pkgs.autoPatchelfHook
          pkgs.wrapGAppsHook
          pkgs.lndir
          pkgs.jq
          pkgs.gtk3
        ];

        buildInputs = with pkgs; [
          # Standard GUI libs
          gtk3
          glib
          pango
          cairo
          gdk-pixbuf
          atk
          libxkbcommon
          
          # C++ and Audio
          stdenv.cc.cc.lib
          alsa-lib
          
          # GSettings runtime schemas
          gsettings-desktop-schemas

          # Font and Graphics
          fontconfig
          libglvnd
          at-spi2-atk

          # *** THE FINAL FIX IS HERE ***
          # Provide a complete desktop environment that the bundled Gecko engine expects.
          # The crash during `_dl_init` strongly suggests one of these is needed
          # by a library's constructor function.

          # 1. For Inter-Process Communication (very common dependency)
          dbus

          # 2. For SVG icon support (a common GTK module)
          librsvg

          # 3. The full suite of X11 client libraries for windowing.
          xorg.libX11
          xorg.libXcomposite
          xorg.libXdamage
          xorg.libXfixes
          xorg.libXrandr
          xorg.libXrender
          xorg.libXtst
        ];

        gappsWrapperArgs = [
          # *** THE FIX IS HERE ***
          # Use the full `pkgs.` prefix because `with` is not in scope here.
          "--prefix XDG_DATA_DIRS : ${pkgs.gsettings-desktop-schemas}/share"
          "--prefix XDG_DATA_DIRS : ${pkgs.gtk3}/share"
          
          # Add the application's own library path to LD_LIBRARY_PATH
          "--prefix LD_LIBRARY_PATH : ${placeholder "out"}/lib/${pname}"
        ];

        installPhase = ''
          runHook preInstall

          mkdir -p $out/lib/${pname}
          cp -r ./* $out/lib/${pname}/

          mkdir -p $out/bin

          # *** BYPASS THE STARTUP SCRIPT ***
          # Symlink the REAL binary into $out/bin.
          # wrapGAppsHook will find this and create a wrapper script for it.
          ln -s $out/lib/${pname}/camoufox $out/bin/camoufox
          ln -s $out/lib/${pname}/camoufox-bin $out/bin/camoufox-bin
          

          runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "A stealthy, minimalistic, custom build of Firefox for web scraping";
          homepage = "https://github.com/daijro/camoufox";
          license = licenses.mit;
          maintainers = with maintainers; [ your-github-username ]; # Change this!
          platforms = platforms.linux;
        };
      };

    in
    {
      packages.${system} = {
        camoufox = camoufox-pkg;
        default = camoufox-pkg;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ self.packages.${system}.camoufox ];
      };
    };
}