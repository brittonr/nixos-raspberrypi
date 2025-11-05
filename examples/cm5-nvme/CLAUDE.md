# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this CM5 NixOS configuration example.

## Project Overview

This is a minimal NixOS configuration example for the Raspberry Pi Compute Module 5 (CM5), demonstrating NVMe boot via PCIe using the nixos-raspberrypi flake.

## nixos-raspberrypi Framework

The CM5 installation uses the [nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi) flake, which provides unopinionated Nix infrastructure for NixOS on Raspberry Pi devices.

### Key Features

**Bootloader Infrastructure**: Manages `/boot/firmware` partition with automatic provisioning during NixOS generation switch, enabling tools like nixos-anywhere (note: kexec is not supported on Pi).

**Boot Methods** (configured via `boot.loader.raspberryPi.bootloader`):
- `kernelboot` - Legacy bootloader (default for RPi5)
- `uboot` - Default for non-Pi5 boards
- `kernel` - New generational bootloader supporting multiple NixOS generations, **recommended for new installations**

**Vendor Packages**: Provides `pkgs.linuxAndFirmware.default` with compatible kernel, firmware, device trees, and wireless firmware for each board model.

**Binary Cache**: Available at `https://nixos-raspberrypi.cachix.org` to avoid rebuilding optimized packages.

### Usage Pattern

The flake provides helper functions as drop-in replacements for `nixpkgs.lib.nixosSystem`:

```nix
nixosConfigurations.rpi5 = nixos-raspberrypi.lib.nixosSystemFull {
  specialArgs = inputs;
  modules = [
    {
      imports = with nixos-raspberrypi.nixosModules; [
        raspberry-pi-5.base           # Base board support
        raspberry-pi-5.page-size-16k  # Recommended: 16k page size optimizations
        raspberry-pi-5.display-vc4    # Display configuration
        raspberry-pi-5.bluetooth      # Bluetooth support
      ];
    }
    # ... your configuration
  ];
};
```

### Important nixos-raspberrypi Modules

**Base Board Support**:
- `raspberry-pi-02.base` / `raspberry-pi-3.base` / `raspberry-pi-4.base` / `raspberry-pi-5.base`

**RPi5-Specific**:
- `raspberry-pi-5.page-size-16k` - Optimizations for 16k memory page size (recommended)
- `raspberry-pi-5.display-vc4` - For regular displays
- `raspberry-pi-5.display-rp1` - For RP1-connected displays (DPI/composite/MIPI DSI)

**All Boards**:
- `usb-gadget-ethernet` - Ethernet emulation over USB

### Firmware Configuration

**Bootloader options**: `boot.loader.raspberryPi.*` (see `modules/system/boot/loader/raspberrypi/default.nix`)

**config.txt settings**: `hardware.raspberry-pi.config.*` for Raspberry Pi firmware configuration

Example:
```nix
hardware.raspberry-pi.config = {
  all = {
    options = {
      enable_uart = { enable = true; value = true; };
    };
    base-dt-params = {
      pciex1 = { enable = true; value = "on"; };
      pciex1_gen = { enable = true; value = "3"; };
    };
  };
};
```

### Installer Images

Pre-built SD card images available (based on nixos-images):
- Mutable images suitable for both installation media and ready-to-use systems
- mDNS enabled, `iwd` for easier WLAN configuration
- Auto-expand partition table on first boot
- New generational bootloader for RPi5 by default

Build with:
```bash
nix build github:nvmd/nixos-raspberrypi#installerImages.rpi5
nix build github:nvmd/nixos-raspberrypi#installerImages.rpi4
```

### Deployment Methods

**With nixos-anywhere** (uses disko for disk setup):
```bash
nixos-anywhere --flake .#<system> root@<hostname>
```

**To running system**:
```bash
nixos-rebuild switch --flake .#<system> --target-host root@<hostname>
```

**Important**: kexec is not supported on Raspberry Pi, so standard nixos-install workflows don't work.

## Raspberry Pi CM5 Installation Workflow

This repository also contains a CM5 (Raspberry Pi Compute Module 5) NixOS installation configuration at the root level.

### CM5 Architecture
- **Bootloader**: Uses nixos-raspberrypi flake for Pi 5 support with kernel bootloader mode
- **Storage**: Boots from NVMe via PCIe Gen 3.0
- **Installation Method**: USB mass storage gadget mode via rpiboot
- **Cross-compilation**: Build on aarch64 host (m2) to avoid cross-compilation issues

### CM5 Build Process

The CM5 configuration cannot be built directly on x86_64 due to architecture mismatch. Use a remote aarch64 builder:

```bash
# 1. Sync configuration to aarch64 build host (m2)
rsync -avz --exclude='.git' /home/brittonr/git/test/ root@m2:/tmp/cm5-build/

# 2. Build on aarch64 host
ssh root@m2 'cd /tmp/cm5-build && rm -f result microvm-demo.sock current && nix build .#nixosConfigurations.cm5.config.system.build.toplevel'

# 3. Get the built system path
ssh root@m2 'cd /tmp/cm5-build && readlink result'
```

### CM5 Installation to NVMe

The installation process uses rpiboot to expose the CM5's NVMe as USB mass storage.

**Prerequisites**: Clone and build the Raspberry Pi usbboot utilities:
```bash
git clone https://github.com/raspberrypi/usbboot
cd usbboot
make
```

**Installation steps**:

```bash
# 1. Enter USB boot mode
cd usbboot/mass-storage-gadget64
sudo ../rpiboot -d .

# 2. The NVMe appears as /dev/sdX (varies) - verify with lsblk

# 3. Mount partitions (adjust device as needed)
sudo mount /dev/sdc2 /mnt
sudo mount /dev/sdc1 /mnt/boot/firmware

# 4. Copy the built system closure to target
sudo nix copy --to /mnt --no-check-sigs /nix/store/<system-path>

# 5. Set up system profile
sudo mkdir -p /mnt/nix/var/nix/profiles
sudo ln -sf /nix/store/<system-path> /mnt/nix/var/nix/profiles/system

# 6. Create /init symlink (required by kernel)
sudo ln -sf /nix/store/<system-path>/init /mnt/init

# 7. Set partition labels (must match disko config)
sudo parted /dev/sdc
(parted) name 1 disk-main-FIRMWARE  # uppercase FIRMWARE
(parted) name 2 disk-main-root
(parted) quit

# 8. Populate boot files
sudo cp /nix/store/<system-path>/kernel /mnt/boot/firmware/Image
sudo cp /nix/store/<system-path>/initrd /mnt/boot/firmware/initrd
sudo cp -r /nix/store/<system-path>/dtbs/* /mnt/boot/firmware/

# 9. Create boot configuration files (use helper files in repo root)
sudo cp config.txt /mnt/boot/firmware/config.txt
sudo cp cmdline.txt /mnt/boot/firmware/cmdline.txt

# 10. Unmount and reboot CM5
sudo umount /mnt/boot/firmware
sudo umount /mnt
# Stop rpiboot, disconnect USB, power cycle CM5
```

### CM5 Boot Files

The boot partition requires specific files and configuration:

**config.txt** - Raspberry Pi boot configuration:
```
[pi5]
kernel=Image
initramfs initrd followkernel
arm_64bit=1
enable_uart=1
uart_2ndstage=1
dtparam=pciex1           # Enable PCIe for NVMe
dtparam=pciex1_gen=3     # Force Gen 3.0
os_check=0
```

**cmdline.txt** - Kernel command line (single line, no newlines):
```
console=serial0,115200n8 console=tty1 loglevel=7 lsm=landlock,yama,bpf root=/dev/disk/by-uuid/<uuid> init=/nix/store/<system-path>/init
```

### CM5 Important Notes

- **Device paths change**: The NVMe device appears as different /dev/sdX each time in USB gadget mode - always verify with `lsblk`
- **Partition labels critical**: The initrd looks for `/dev/disk/by-partlabel/disk-main-root` and `/dev/disk/by-partlabel/disk-main-FIRMWARE` (case-sensitive)
- **Root UUID required**: cmdline.txt must specify the actual UUID from `blkid`
- **Cross-compilation fails**: Build on aarch64 host, not x86_64, to avoid builder exit code 255 errors
- **Binary cache trust**: The nixos-raspberrypi cachix requires trusted-users configuration
- **kexec not supported**: Cannot use nixos-install with kexec on Pi 5, must use manual installation method above

### CM5 Files

- `flake.nix` - CM5 flake configuration
- `configuration.nix` - CM5 NixOS configuration
- `disko-config.nix` - Disk partitioning for CM5 NVMe
- `config.txt` - Pi boot config template
- `cmdline.txt` - Kernel cmdline template
- `nixos-raspberrypi-demo/` - Additional example configurations

## External Documentation

- [nixos-raspberrypi GitHub](https://github.com/nvmd/nixos-raspberrypi) - Upstream flake providing Pi 5 support
- [NixOS on ARM/Raspberry Pi 5 Wiki](https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_5) - NixOS ARM wiki
- [Raspberry Pi usbboot](https://github.com/raspberrypi/usbboot) - USB boot utilities for installation
- [NixOS Options Search](https://search.nixos.org/options) - Search all NixOS options
- [Noogle - Nix Function Search](https://noogle.dev/) - Search Nix functions