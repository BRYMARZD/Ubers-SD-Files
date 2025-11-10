# Orange Pi 5 Plus - Armbian Build Instructions

## Configuration Details

Your Orange Pi 5 Plus image is configured with:

### Hardware Support
- **Board**: Orange Pi 5 Plus (RK3588 SoC)
- **UEFI**: EDK2 UEFI firmware (automatically downloaded from edk2-porting/edk2-rk3588)
- **Bootloader**: GRUB with Device Tree Blob (DTB) support
- **GPU**: Panthor GPU with Mesa driver
- **VPU**: Hardware video acceleration (4K support)
- **Multimedia**: Rockchip multimedia stack with Chromium hardware acceleration

### Software Stack
- **OS**: Debian 14 (Forky) - Latest Debian
- **Kernel**: Vendor 6.1 (rk-6.1-rkr5.1) with RK3588 optimizations
- **Desktop**: GNOME with Wayland support
- **Graphics**: Mesa with Panthor driver for RK3588
- **Video**: GStreamer with rockchip plugins, libv4l-rkmpp for hardware decode

### Enabled Extensions

1. **uefi-edk2-rk3588** (`armbian-build/extensions/uefi-edk2-rk3588.sh`)
   - Downloads latest EDK2 UEFI firmware from GitHub
   - Writes UEFI image to SPI flash area
   - Automatically enables `grub-with-dtb` extension
   - Creates GPT partition table
   - Adds `-edk2` suffix to image name

2. **grub-with-dtb** (`armbian-build/extensions/grub-with-dtb.sh`)
   - Enables GRUB bootloader with Device Tree support
   - Uses DTB file: `rockchip/rk3588-orangepi-5-plus.dtb`
   - Deploys DTB to boot partition automatically
   - Includes kernel hooks for automatic DTB updates
   - Custom GRUB script: `/etc/grub.d/09_linux_with_dtb.sh`

3. **mesa-vpu** (`armbian-build/extensions/mesa-vpu.sh`)
   - Enables Panthor GPU overlay for vendor kernel
   - Installs Mesa with hardware acceleration
   - Adds rockchip-multimedia packages:
     - `rockchip-multimedia-config`
     - `chromium` (with hardware decode)
     - `libv4l-rkmpp` (hardware video decode)
     - `gstreamer1.0-rockchip` (hardware video processing)
     - `libwidevinecdm` (DRM support)
   - Enables 4K video playback acceleration
   - Includes glmark2 benchmarks for testing

## Building the Image

### Option 1: Using Docker (Recommended)

On your local machine with Docker installed:

```bash
# Clone the repository with submodules
git clone --recursive https://github.com/BRYMARZD/Ubers-SD-Files
cd Ubers-SD-Files/armbian-build

# Build using Docker with privileged mode (required for binfmt_misc)
docker run --rm --privileged \
  -v $(pwd):/build \
  -v $(pwd)/output:/build/output \
  ghcr.io/armbian/build:latest \
  /build/compile.sh \
  docker \
  userpatches=/build/userpatches \
  BOARD=orangepi5-plus \
  BRANCH=vendor \
  RELEASE=forky \
  BUILD_DESKTOP=yes \
  DESKTOP_ENVIRONMENT=gnome \
  DESKTOP_ENVIRONMENT_CONFIG_NAME=config_base \
  DESKTOP_APPGROUPS_SELECTED="" \
  KERNEL_CONFIGURE=no \
  ENABLE_EXTENSIONS="uefi-edk2-rk3588,mesa-vpu" \
  COMPRESS_OUTPUTIMAGE="sha,img,xz" \
  EXPERT=yes
```

### Option 2: Using Configuration File

```bash
cd armbian-build
./compile.sh docker \
  CONFIG_FILE=userpatches/config-orangepi5plus-uefi.conf
```

### Option 3: Native Linux Build

On Ubuntu 24.04 or Debian system:

```bash
cd armbian-build
sudo ./compile.sh build \
  CONFIG_FILE=userpatches/config-orangepi5plus-uefi.conf
```

Or with inline parameters:

```bash
sudo ./compile.sh build \
  BOARD=orangepi5-plus \
  BRANCH=vendor \
  RELEASE=forky \
  BUILD_DESKTOP=yes \
  DESKTOP_ENVIRONMENT=gnome \
  ENABLE_EXTENSIONS="uefi-edk2-rk3588,mesa-vpu" \
  EXPERT=yes
```

## Build Output

After successful build, you'll find:

- **Image location**: `armbian-build/output/images/`
- **Image name**: `Armbian_<version>_Orangepi5-plus_forky_vendor_<kernel>_gnome-edk2.img.xz`
- **Checksum**: `Armbian_<version>_Orangepi5-plus_forky_vendor_<kernel>_gnome-edk2.img.sha`

## Flashing the Image

### To SD Card or eMMC:

```bash
# Extract the image
unxz Armbian_*.img.xz

# Flash to SD card (replace /dev/sdX with your device)
sudo dd if=Armbian_*.img of=/dev/sdX bs=4M status=progress conv=fsync
```

### Your UEFI Setup

Since you already have EDK2 UEFI on SPI flash:
1. The image will boot directly via UEFI/GRUB
2. GRUB will load the kernel with proper DTB
3. No need to flash anything to SPI (it's already there)
4. Just write the image to SD/eMMC/NVMe

## What You Get

### UEFI Boot Chain:
```
SPI EDK2 UEFI → GRUB (with DTB) → Linux Kernel → GNOME Desktop
```

### Hardware Acceleration:
- ✅ 3D Graphics (Mesa Panthor driver)
- ✅ Video Decode (VPU via libv4l-rkmpp)
- ✅ Video Encode (VPU via GStreamer rockchip plugins)
- ✅ Chromium with hardware decode
- ✅ 4K video playback
- ✅ Wayland compositor with GPU acceleration

### Testing Hardware Acceleration:

```bash
# Test OpenGL
glmark2
glmark2-es2
glmark2-wayland

# Test video decode
chromium --enable-features=VaapiVideoDecoder
mpv --hwdec=auto your-4k-video.mp4

# Check GPU
glxinfo | grep -i opengl
```

## Troubleshooting

### If UEFI doesn't boot:
1. Ensure EDK2 is properly flashed to SPI
2. Check UEFI boot order (should prioritize the boot device)
3. Verify GPT partition table on the image

### If no hardware acceleration:
```bash
# Check if panthor is loaded
dmesg | grep panthor

# Check Mesa version
glxinfo | grep "OpenGL version"

# Check VPU
v4l2-ctl --list-devices
```

## Build Time Estimate

- **CPU**: Depends on host CPU (2-4 hours on modern 8-core CPU)
- **Kernel**: ~30-60 minutes
- **U-Boot**: ~10 minutes
- **Root filesystem**: ~30-60 minutes
- **Desktop packages**: ~30 minutes
- **Total**: ~2-5 hours

## System Requirements for Building

- **RAM**: 8GB minimum (16GB recommended)
- **Disk**: 50GB free space
- **OS**: Ubuntu 24.04 / Debian 12+ / Any Linux with Docker
- **CPU**: Multi-core recommended (8+ cores ideal)

## Notes

- The `vendor` kernel branch provides the best hardware support for RK3588
- Mesa VPU extension only works with vendor or legacy kernels
- GNOME is configured for Wayland by default (best for Panthor GPU)
- EDK2 UEFI firmware is downloaded automatically during build
- GRUB config includes `acpi=off` for better SBC compatibility
