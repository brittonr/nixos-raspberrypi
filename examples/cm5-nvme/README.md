# CM5 NixOS

NixOS configuration for Raspberry Pi Compute Module 5 (CM5) with NVMe boot support.

## Overview

This repository provides a minimal NixOS configuration for the Raspberry Pi Compute Module 5, leveraging the [nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi) flake for unopinionated Pi 5 infrastructure support.

## Key Features

- NVMe boot via PCIe Gen 3.0
- Kernel bootloader with generational support
- USB mass storage installation method via rpiboot
- 16k page size optimizations for Pi 5
- Serial console debugging enabled
- SSH access configured

## Quick Start

### Prerequisites: USB Boot Utilities

The CM5 installation uses **rpiboot** to expose the NVMe drive as USB mass storage. Clone and build the utilities:

```bash
# Clone the Raspberry Pi usbboot repository
git clone --recurse-submodules --shallow-submodules --depth=1 https://github.com/raspberrypi/usbboot
cd usbboot

# Install dependencies (Debian/Ubuntu)
sudo apt install git libusb-1.0-0-dev pkg-config build-essential

# Build rpiboot
make

# Test (optional - will wait for a Pi to be connected in USB boot mode)
sudo ./rpiboot -h
```

### Entering USB Mass Storage Mode

1. **Power off the CM5** completely
2. **Enable boot mode**: Set the `nRPIBOOT` jumper on your CM5 IO board (check your board's documentation for location)
3. **Connect USB cable** between your computer and the CM5
4. **Power on the CM5**
5. **Run rpiboot**:

```bash
cd usbboot/mass-storage-gadget64
sudo ../rpiboot -d .
```

You should see output indicating the boot stages, ending with "Second stage boot server done". The CM5's NVMe drive will now appear as `/dev/sdX` on your computer.

**Verify the drive appeared:**
```bash
lsblk
# Look for a new ~1TB drive (or whatever size your NVMe is)
```

### Building the Configuration

Build on an aarch64 host to avoid cross-compilation issues:

```bash
# On aarch64 system (or remote builder)
nix build .#nixosConfigurations.cm5.config.system.build.toplevel
```

### Installation Overview

Once in USB mass storage mode:

1. Partition and format the NVMe drive
2. Mount the partitions
3. Copy the built NixOS system closure
4. Set up boot files (kernel, initrd, config.txt, cmdline.txt)
5. Unmount, disconnect, and reboot the CM5

For detailed installation instructions including:
- Disk partitioning and mounting steps
- System closure installation commands
- Boot file configuration details
- Partition label requirements
- Troubleshooting tips

See [CLAUDE.md](CLAUDE.md) for complete installation workflow.

## Repository Structure

- `flake.nix` - Flake configuration using nixos-raspberrypi
- `configuration.nix` - NixOS system configuration
- `disko-config.nix` - Declarative disk partitioning (2-partition layout)
- `config.txt` / `cmdline.txt` - Raspberry Pi boot configuration templates
- `nixos-raspberrypi-demo/` - Additional example configurations

## Technology Stack

- NixOS unstable
- nixos-raspberrypi flake (Pi 5 base modules)
- disko for disk management
- Binary cache: https://nixos-raspberrypi.cachix.org

## Documentation

Detailed installation procedures, architecture notes, and troubleshooting information are available in [CLAUDE.md](CLAUDE.md).

## External Resources

- [nixos-raspberrypi GitHub](https://github.com/nvmd/nixos-raspberrypi) - Upstream flake
- [Raspberry Pi usbboot](https://github.com/raspberrypi/usbboot) - USB boot utilities (required for installation)
- [NixOS on ARM/Raspberry Pi 5 Wiki](https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_5) - NixOS ARM documentation
- [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/) - Official Pi documentation
