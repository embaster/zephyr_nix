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
      in
      {
        devShells.default = pkgs.mkShell {
          name = "zephyr-dev-shell-manual";

          # We must now manually specify every dependency that zephyr-nix provided.
          buildInputs = with pkgs; [
            # 1. The Cross-Compiler Toolchain
            # This is the C compiler and associated tools for the ARM target.
            gcc-arm-embedded 

            # 2. The Zephyr meta-tool
            # This is now pulled directly from nixpkgs.
            python313Packages.west
            python313Packages.pyelftools

            # 3. Build System Tools
            # Zephyr uses CMake, Ninja, and Python for its build process.
            cmake
            ninja
            python3 # West and other scripts depend on python
            dtc     # Device Tree Compiler
            gperf
            git

            # 4. Debugging and Emulation Tools
            openocd # For flashing and debugging on hardware
            #qemu    # For running projects in an emulator

            probe-rs

            # 5. Include non-free packages
            segger-jlink
          ];
        
          gnuarmemb = pkgs.gcc-arm-embedded;

          # With zephyr-nix gone, we must configure the environment ourselves.
          shellHook = ''
            echo "----------------------------------------------------"
            echo "   Welcome to the Zephyr RTOS dev environment!    "
            echo "       (Manually configured without zephyr-nix)     "
            echo "----------------------------------------------------"

            # This tells Zephyr's build system to use the GNU ARM Embedded toolchain.
            export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb

            # Now we use the simple environment variable `$gnuarmemb`.
            # This is a standard shell variable expansion, not Nix interpolation.w
            export GNUARMEMB_TOOLCHAIN_PATH="$gnuarmemb"

            # Unset ZEPHYR_BASE to ensure west can correctly manage the source tree.
            unset ZEPHYR_BASE

            # The rest of your excellent hook for checking the west workspace remains.
            if [ ! -d ".west" ]; then
              echo
              echo "Zephyr workspace not found."
              echo "To initialize your project, run the following commands:"
              echo
              echo "  west init -m https://github.com/zephyrproject-rtos/zephyr --mr main"
              echo "  west update"
              echo
            else
              echo
              echo "Zephyr workspace found."
              echo "To build the hello_world sample for the qemu_cortex_m3 board, run:"
              echo
              echo "  west build -b qemu_cortex_m3 zephyr/samples/hello_world"
              echo
            fi
            echo "----------------------------------------------------"
          '';
        };
      }
    );
}
