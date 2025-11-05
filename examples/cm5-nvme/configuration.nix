{ config, pkgs, lib, ... }:
{
  # PCIe/NVMe configuration - this goes into config.txt
  hardware.raspberry-pi.config = {
    all = {
      options = {
        # Serial console for debugging
        enable_uart = {
          enable = true;
          value = true;
        };
        uart_2ndstage = {
          enable = true;
          value = true;
        };
      };
      
      base-dt-params = {
        # Enable PCIe for NVMe
        pciex1 = {
          enable = true;
          value = "on";
        };
        # Force PCIe Gen 3.0 for better performance
        pciex1_gen = {
          enable = true;
          value = "3";
        };
      };
    };
  };

  # Use the new kernel bootloader for Pi 5
  boot.loader.raspberryPi.bootloader = "kernel";

  networking.hostName = "cm5-nixos";
  networking.useDHCP = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYzh3yIsSTOYXkJMFHBKzkakoDfonm3/RED5rqMqhIO britton@framework"
  ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  system.stateVersion = "24.11";
}
