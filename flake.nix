{
  description = "A development environment for Zephyr RTOS (manual setup)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # The zephyr-nix input has been removed.
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # We now use a vanilla nixpkgs instance without any overlays.
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          config.segger-jlink.acceptLicense = true;
          config.permittedInsecurePackages = [
            "segger-jlink-qt4-810"
          ];
        };
        # Python packages needed for Zephyr
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          west
          pyelftools
          pyyaml
          pykwalify
          canopen
          packaging
          progress
          psutil
          anytree
          intelhex
          cryptography
          click
          colorama
          plyvel
          cbor2
          # Add other Python dependencies as needed
        ]);
        
        # Zephyr SDK version - update this to pin a specific version
        zephyr-sdk-version = "0.17.4";
        
        # zephyr-sdk = pkgs.stdenv.mkDerivation rec {
        #   pname = "zephyr-sdk";
        #   version = zephyr-sdk-version;
          
        #   src = pkgs.fetchurl {
        #     url = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${version}/zephyr-sdk-${version}_linux-x86_64.tar.xz";
        #     sha256 = "sha256-g/LzJ9ui1s8kQPIvL1AQQVRNfzTvi4eOzYP0UT0RFrY="; # Update with actual hash
        #   };
          
        #   nativeBuildInputs = [ pkgs.autoPatchelfHook ];
          
        #   installPhase = ''
        #     mkdir -p $out
        #     cp -r * $out/
            
        #     # Setup SDK
        #     cd $out
        #     ./setup.sh -t arm-zephyr-eabi -h -c
        #   '';
          
        #   meta = with pkgs.lib; {
        #     description = "Zephyr SDK";
        #     homepage = "https://github.com/zephyrproject-rtos/sdk-ng";
        #     platforms = platforms.linux;
        #   };
        # };
      in
     {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Core development tools
            git
            cmake
            ninja
            gperf
            ccache
            dfu-util
            mcuboot-imgtool

            # Toolchain
            # ARM Cortex-M embedded toolchain
            gcc-arm-embedded  # For ARM Cortex-M
            # alternative: Zephyr SDK
            #zephyr-sdk
            
            # Python environment with Zephyr tools
            pythonEnv
            
            # Additional tools
            dtc  # Device Tree Compiler
            openocd
            gdb
            minicom
            screen
            
            # Nordic tools (for nRF52840)
            nrf-command-line-tools
            
            # Optional: J-Link tools
            segger-jlink
          ];

          shellHook = ''
            # echo "🚀 Zephyr Development Environment"
            # echo "Zephyr SDK:
            
            # # Set up environment variables
            # export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
            # export ZEPHYR_SDK_INSTALL_DIR=
            
            # Initialize west workspace if not already done
            if [ ! -f .west/config ]; then
              echo "Initializing west workspace..."
              west init -l .
              west update
            fi
            
            # Source Zephyr environment
            if [ -f zephyr/zephyr-env.sh ]; then
              source zephyr/zephyr-env.sh
              echo "✅ Zephyr environment activated"
            else
              echo "⚠️  Run 'west update' to fetch Zephyr source"
            fi
            
            echo "📁 Project root: $(pwd)"
            echo "🔧 Available commands:"
            echo "   west build -b nrf52840dk_nrf52840 ."
            echo "   west flash"
            echo "   west debug"
          '';
        };
      } 
    );
}
