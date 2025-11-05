{ config, lib, ... }:

{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/sdb";
      content = {
        type = "gpt";
        partitions = {
          firmware = {
            name = "FIRMWARE";
            size = "512M";
            type = "0700";  # Microsoft basic data
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/firmware";
              mountOptions = [ "noatime" ];
            };
          };
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
