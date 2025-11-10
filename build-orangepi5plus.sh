#!/bin/bash
#
# Orange Pi 5 Plus - Armbian Build Script
# Builds Debian 14 (Forky) with GNOME, EDK2 UEFI, GRUB+DTB, and Mesa VPU
#

set -e

echo "=============================================="
echo "Orange Pi 5 Plus - UEFI Image Builder"
echo "=============================================="
echo ""
echo "Configuration:"
echo "  Board: Orange Pi 5 Plus (RK3588)"
echo "  OS: Debian 14 (Forky)"
echo "  Kernel: Vendor 6.1 with RK3588 optimizations"
echo "  Desktop: GNOME"
echo "  UEFI: EDK2 (uefi-edk2-rk3588 extension)"
echo "  Bootloader: GRUB with DTB (grub-with-dtb extension)"
echo "  GPU: Mesa Panthor"
echo "  VPU: Hardware acceleration (mesa-vpu extension)"
echo ""
echo "=============================================="
echo ""

# Get script directory
SCRIPT_DIR="$(dirname "$0")"

# Copy config to armbian-build/userpatches if it doesn't exist
mkdir -p "${SCRIPT_DIR}/armbian-build/userpatches"
if [ -f "${SCRIPT_DIR}/armbian-configs/config-orangepi5plus-uefi.conf" ]; then
    cp "${SCRIPT_DIR}/armbian-configs/config-orangepi5plus-uefi.conf" \
       "${SCRIPT_DIR}/armbian-build/userpatches/"
    echo "Copied configuration file to armbian-build/userpatches/"
fi

# Change to armbian-build directory
cd "${SCRIPT_DIR}/armbian-build"

# Check if we're in Docker
if [ -f /.dockerenv ]; then
    echo "Running inside Docker container..."
    BUILD_METHOD="native"
else
    # Check if Docker is available
    if command -v docker &> /dev/null; then
        echo "Docker detected. Recommend using Docker for build."
        echo ""
        read -p "Use Docker for build? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            BUILD_METHOD="docker"
        else
            BUILD_METHOD="native"
        fi
    else
        echo "Docker not found. Using native build method."
        BUILD_METHOD="native"
    fi
fi

# Common build parameters
BUILD_PARAMS=(
    "BOARD=orangepi5-plus"
    "BRANCH=vendor"
    "RELEASE=forky"
    "BUILD_DESKTOP=yes"
    "DESKTOP_ENVIRONMENT=gnome"
    "DESKTOP_ENVIRONMENT_CONFIG_NAME=config_base"
    "DESKTOP_APPGROUPS_SELECTED="
    "KERNEL_CONFIGURE=no"
    "ENABLE_EXTENSIONS=uefi-edk2-rk3588,mesa-vpu"
    "COMPRESS_OUTPUTIMAGE=sha,img,xz"
    "EXPERT=yes"
    "GRUB_CMDLINE_LINUX_DEFAULT=acpi=off"
)

echo "=============================================="
echo "Starting build..."
echo "=============================================="
echo ""

if [ "$BUILD_METHOD" = "docker" ]; then
    echo "Building with Docker (privileged mode for cross-compilation)..."
    docker run --rm --privileged \
        -v "$(pwd)":/build \
        -v "$(pwd)/output":/build/output \
        -e ALLOW_ROOT=yes \
        ghcr.io/armbian/build:latest \
        /build/compile.sh \
        docker \
        "${BUILD_PARAMS[@]}"
else
    echo "Building natively..."
    if [ "$EUID" -ne 0 ]; then
        echo "Native build requires root privileges."
        exec sudo bash "$0" "$@"
    fi

    ./compile.sh build "${BUILD_PARAMS[@]}"
fi

echo ""
echo "=============================================="
echo "Build complete!"
echo "=============================================="
echo ""
echo "Your image is located in: armbian-build/output/images/"
echo ""
echo "Flash to SD/eMMC/NVMe with:"
echo "  unxz Armbian_*.img.xz"
echo "  sudo dd if=Armbian_*.img of=/dev/sdX bs=4M status=progress conv=fsync"
echo ""
echo "Your Orange Pi 5 Plus with EDK2 UEFI will boot automatically!"
echo ""
