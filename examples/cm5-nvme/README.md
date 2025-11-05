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

### Building the Configuration

Build on an aarch64 host to avoid cross-compilation issues:

```bash
# On aarch64 system (or remote builder)
nix build .#nixosConfigurations.cm5.config.system.build.toplevel
```

For detailed installation instructions including:
- USB mass storage gadget setup
- Disk partitioning and mounting
- System closure installation
- Boot file configuration
- Troubleshooting tips

See [CLAUDE.md](CLAUDE.md) for complete installation workflow.

## Repository Structure

- `flake.nix` - Flake configuration using nixos-raspberrypi
- `configuration.nix` - NixOS system configuration
- `disko-config.nix` - Declarative disk partitioning (2-partition layout)
- `usbboot/` - Raspberry Pi USB boot utilities for mass storage mode

## Technology Stack

- NixOS unstable
- nixos-raspberrypi flake (Pi 5 base modules)
- disko for disk management
- Binary cache: https://nixos-raspberrypi.cachix.org

## Documentation

Detailed installation procedures, architecture notes, and troubleshooting information are available in [CLAUDE.md](CLAUDE.md).

## External Resources

- [nixos-raspberrypi GitHub](https://github.com/nvmd/nixos-raspberrypi)
- [NixOS on ARM/Raspberry Pi 5 Wiki](https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_5)
- [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/)
